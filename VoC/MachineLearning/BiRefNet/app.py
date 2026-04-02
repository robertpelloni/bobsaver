import os
import torch
import cv2
import numpy as np
import gradio as gr
from PIL import Image
from torchvision import transforms
from transformers import AutoModelForImageSegmentation

torch.set_float32_matmul_precision(['high', 'highest'][0])

def refine_foreground(image, mask, r=90):
    """Identical to notebook implementation"""
    if mask.size != image.size:
        mask = mask.resize(image.size)
    image = np.array(image) / 255.0
    mask = np.array(mask) / 255.0
    
    # First pass
    alpha = mask[:, :, None]
    blurred_alpha = cv2.blur(alpha, (r, r))[:, :, None]
    blurred_FA = cv2.blur(image * alpha, (r, r))
    blurred_F = blurred_FA / (blurred_alpha + 1e-5)
    blurred_B1A = cv2.blur(image * (1 - alpha), (r, r))
    blurred_B = blurred_B1A / ((1 - blurred_alpha) + 1e-5)
    F = blurred_F + alpha * (image - alpha * blurred_F - (1 - alpha) * blurred_B)
    
    # Second refinement pass
    r2 = 6
    blurred_alpha = cv2.blur(alpha, (r2, r2))[:, :, None]
    blurred_FA = cv2.blur(F * alpha, (r2, r2))
    blurred_F = blurred_FA / (blurred_alpha + 1e-5)
    blurred_B1A = cv2.blur(blurred_B * (1 - alpha), (r2, r2))
    blurred_B = blurred_B1A / ((1 - blurred_alpha) + 1e-5)
    F = blurred_F + alpha * (image - alpha * blurred_F - (1 - alpha) * blurred_B)
    
    return Image.fromarray((np.clip(F, 0, 1) * 255.0).astype(np.uint8))

# Cache for models
model_cache = {}

def process_image(input_image, model_name, resolution, output_type):
    # Load or retrieve cached model
    if model_name not in model_cache:
        model_cache[model_name] = AutoModelForImageSegmentation.from_pretrained(
            model_name, trust_remote_code=True
        ).to("cuda").eval().half()
    model = model_cache[model_name]
    
    # Process input
    width, height = map(int, resolution.split('x'))
    transform = transforms.Compose([
        transforms.Resize((height, width)),
        transforms.ToTensor(),
        transforms.Normalize([0.485, 0.456, 0.406], [0.229, 0.224, 0.225])
    ])
    
    img = Image.fromarray(input_image).convert("RGB")
    tensor = transform(img).unsqueeze(0).to("cuda").half()
    
    # Generate prediction
    with torch.no_grad():
        pred = model(tensor)[-1].sigmoid().cpu()
    
    mask = transforms.ToPILImage()(pred.squeeze())
    mask_resized = mask.resize(img.size)
    
    # Generate output based on type
    if output_type == "mask":
        return np.array(mask_resized)
    elif output_type == "transparent":
        foreground = refine_foreground(img, mask)
        foreground.putalpha(mask_resized)
        return np.array(foreground)
    else:  # composite
        foreground = refine_foreground(img, mask)
        foreground.putalpha(mask_resized)
        
        # Green screen composition
        array_foreground = np.array(foreground)[:, :, :3].astype(np.float32)
        array_mask = (np.array(foreground)[:, :, 3:] / 255).astype(np.float32)
        array_background = np.zeros_like(array_foreground)
        array_background[:, :, :] = (0, 177, 64)  # Green background
        
        return (array_foreground * array_mask + array_background * (1 - array_mask)).astype(np.uint8)

def process_video(input_video, model_name, resolution, output_type, progress=gr.Progress()):
    # Use smaller batch size for video to avoid memory issues
    if model_name not in model_cache:
        model_cache[model_name] = AutoModelForImageSegmentation.from_pretrained(
            model_name, trust_remote_code=True
        ).to("cuda").eval().half()
    model = model_cache[model_name]
    
    # Setup transform
    width, height = map(int, resolution.split('x'))
    transform = transforms.Compose([
        transforms.Resize((height, width)),
        transforms.ToTensor(),
        transforms.Normalize([0.485, 0.456, 0.406], [0.229, 0.224, 0.225])
    ])
    
    # Create temp output file
    temp_dir = os.path.dirname(input_video) if os.path.dirname(input_video) else "."
    output_path = os.path.join(temp_dir, "output_video.mp4")
    
    # Setup video capture and writer
    cap = cv2.VideoCapture(input_video)
    fps = cap.get(cv2.CAP_PROP_FPS)
    total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
    width_out = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
    height_out = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
    
    fourcc = cv2.VideoWriter_fourcc(*'mp4v')
    out = cv2.VideoWriter(output_path, fourcc, fps, (width_out, height_out), True)
    
    # Process frames with memory clearing between batches
    frame_count = 0
    batch_size = 1  # Process one frame at a time for memory efficiency
    
    while frame_count < total_frames:
        # Update progress
        progress(frame_count / total_frames, f"Processing frame {frame_count}/{total_frames}")
        
        # Read frame
        success, frame = cap.read()
        if not success:
            break
        
        # Process frame
        img = Image.fromarray(cv2.cvtColor(frame, cv2.COLOR_BGR2RGB))
        tensor = transform(img).unsqueeze(0).to("cuda").half()
        
        with torch.no_grad():
            pred = model(tensor)[-1].sigmoid().cpu()
        
        # Generate mask
        mask = transforms.ToPILImage()(pred.squeeze())
        mask_resized = mask.resize((width_out, height_out))
        
        # Create output based on type
        if output_type == "mask":
            result_frame = np.array(mask_resized.convert("RGB"))
            out.write(cv2.cvtColor(result_frame, cv2.COLOR_RGB2BGR))
        elif output_type == "transparent":
            # For video, add white background
            foreground = refine_foreground(img, mask)
            foreground.putalpha(mask_resized)
            
            # White background for display
            background = Image.new("RGB", foreground.size, (255, 255, 255))
            background.paste(foreground, mask=foreground.split()[3])
            result_frame = np.array(background)
            out.write(cv2.cvtColor(result_frame, cv2.COLOR_RGB2BGR))
        else:  # composite
            foreground = refine_foreground(img, mask)
            foreground.putalpha(mask_resized)
            
            # Green screen
            array_foreground = np.array(foreground)[:, :, :3].astype(np.float32)
            array_mask = (np.array(foreground)[:, :, 3:] / 255).astype(np.float32) if foreground.mode == "RGBA" else np.ones((*array_foreground.shape[:2], 1))
            array_background = np.zeros_like(array_foreground)
            array_background[:, :, :] = (0, 177, 64)
            
            result_frame = (array_foreground * array_mask + array_background * (1 - array_mask)).astype(np.uint8)
            out.write(cv2.cvtColor(result_frame, cv2.COLOR_RGB2BGR))
        
        frame_count += 1
        
        # Force garbage collection every 10 frames
        if frame_count % 10 == 0:
            torch.cuda.empty_cache()
    
    # Release resources
    cap.release()
    out.release()
    
    return output_path

def create_ui():
    with gr.Blocks(title="BiRefNet Background Remover") as app:
        gr.Markdown("# BiRefNet Background Removal")
        
        with gr.Tabs():
            with gr.Tab("Image"):
                with gr.Row():
                    with gr.Column():
                        input_image = gr.Image(label="Input Image", type="numpy")
                        with gr.Row():
                            img_model = gr.Dropdown(
                                choices=["zhengpeng7/BiRefNet", "zhengpeng7/BiRefNet_HR", "zhengpeng7/BiRefNet_HR-matting", "ZhengPeng7/BiRefNet-portrait"],
                                label="Model",
                                value="zhengpeng7/BiRefNet_HR",
                                info="HR-matting: best for hair detail, HR: better for general use"
                            )
                            img_resolution = gr.Dropdown(
                                choices=["512x512", "1024x1024", "2048x2048"],
                                label="Resolution",
                                value="1024x1024"
                            )
                        img_output = gr.Radio(
                            choices=["mask", "transparent", "composite"],
                            label="Output Type",
                            value="composite"
                        )
                        img_button = gr.Button("Process Image", variant="primary")
                    
                    with gr.Column():
                        output_image = gr.Image(label="Output Image")
            
            with gr.Tab("Video"):
                with gr.Row():
                    with gr.Column():
                        input_video = gr.Video(label="Input Video")
                        with gr.Row():
                            vid_model = gr.Dropdown(
                                choices=["zhengpeng7/BiRefNet", "zhengpeng7/BiRefNet_HR"],
                                label="Model",
                                value="zhengpeng7/BiRefNet",
                                info="Use standard model for videos to avoid memory issues"
                            )
                            vid_resolution = gr.Dropdown(
                                choices=["256x256", "512x512", "1024x1024"],
                                label="Resolution",
                                value="512x512",
                                info="Lower resolution is faster & uses less memory"
                            )
                        vid_output = gr.Radio(
                            choices=["mask", "transparent", "composite"],
                            label="Output Type",
                            value="composite"
                        )
                        vid_button = gr.Button("Process Video", variant="primary")
                    
                    with gr.Column():
                        output_video = gr.Video(label="Output Video")
        
        img_button.click(
            process_image,
            inputs=[input_image, img_model, img_resolution, img_output],
            outputs=output_image
        )
        
        vid_button.click(
            process_video,
            inputs=[input_video, vid_model, vid_resolution, vid_output],
            outputs=output_video
        )
    
    return app

if __name__ == "__main__":
    demo = create_ui()
    demo.launch()