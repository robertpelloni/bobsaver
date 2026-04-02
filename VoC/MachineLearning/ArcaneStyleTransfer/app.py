import torch
import PIL
import gradio as gr
import torch
from utils import align_face
from torchvision import transforms
from huggingface_hub import hf_hub_download

device = "cuda:0" if torch.cuda.is_available() else "cpu"

image_size = 512
transform_size = 1024

means = [0.5, 0.5, 0.5]
stds = [0.5, 0.5, 0.5]

img_transforms = transforms.Compose([
            transforms.ToTensor(),
            transforms.Normalize(means, stds)])
 
model_path = hf_hub_download(repo_id="jjeamin/ArcaneStyleTransfer", filename="pytorch_model.bin")

if 'cuda' in device:
    style_transfer = torch.jit.load(model_path).eval().cuda().half()
    t_stds = torch.tensor(stds).cuda().half()[:,None,None]
    t_means = torch.tensor(means).cuda().half()[:,None,None]
else:
    style_transfer = torch.jit.load(model_path).eval().cpu()
    t_stds = torch.tensor(stds).cpu()[:,None,None]
    t_means = torch.tensor(means).cpu()[:,None,None]

def tensor2im(var):
     return var.mul(t_stds).add(t_means).mul(255.).clamp(0,255).permute(1,2,0)

def proc_pil_img(input_image):
    if 'cuda' in device: 
        transformed_image = img_transforms(input_image)[None,...].cuda().half()
    else:
        transformed_image = img_transforms(input_image)[None,...].cpu()
            
    with torch.no_grad():
        result_image = style_transfer(transformed_image)[0]
        output_image = tensor2im(result_image)
        output_image = output_image.detach().cpu().numpy().astype('uint8')
        output_image = PIL.Image.fromarray(output_image)
    return output_image

def process(im, is_align):
    im = PIL.ImageOps.exif_transpose(im)
    
    if is_align == 'True':
        im = align_face(im, output_size=image_size, transform_size=transform_size)
    else: 
        pass
        
    res = proc_pil_img(im)
    
    return res
        
gr.Interface(
    process, 
    inputs=[gr.inputs.Image(type="pil", label="Input", shape=(image_size, image_size)), gr.inputs.Radio(['True','False'], type="value", default='True', label='face align')],
    outputs=gr.outputs.Image(type="pil", label="Output"),
    title="Arcane Style Transfer",
    description="Gradio demo for Arcane Style Transfer",
    article = "<p style='text-align: center'><a href='https://github.com/jjeamin/anime_style_transfer_pytorch' target='_blank'>Github Repo by jjeamin</a></p> <center><img src='https://visitor-badge.glitch.me/badge?page_id=jjeamin_arcane_st' alt='visitor badge'></center></p>",
    examples=[['billie.png', 'True'], ['gongyoo.jpeg', 'True'], ['IU.png', 'True'], ['elon.png', 'True']],
    enable_queue=True,
    allow_flagging=False,
    allow_screenshot=False
    ).launch(enable_queue=True)
