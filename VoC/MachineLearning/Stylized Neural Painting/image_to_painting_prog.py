# image-to-painting-prog.ipynb
# Original file is located at https://colab.research.google.com/drive/1XwZ4VI12CX2v9561-WD5EJwoSTJPFBbr

"""
model files
https://drive.google.com/file/d/1sqWhgBKqaBJggl2A8sD1bLSq2_B1ScMG/view?usp=sharing
https://drive.google.com/file/d/19Yrj15v9kHvWzkK9o_GSZtvQaJPmcRYQ/view?usp=sharing
https://drive.google.com/file/d/1XsjncjlSdQh2dbZ3X1qf1M8pDc8GLbNy/view?usp=sharing
https://drive.google.com/file/d/162ykmRX8TBGVRnJIof8NeqN7cuwwuzIF/view?usp=sharing
"""

import sys

sys.stdout.write("Imports ...\n")
sys.stdout.flush()

import argparse
import torch
torch.cuda.current_device()
import torch.optim as optim
from painter import *
import PIL

sys.stdout.write("Parsing arguments ...\n")
sys.stdout.flush()

def parse_args():
  desc = "Blah"
  parser = argparse.ArgumentParser(description=desc)
  parser.add_argument('--source_image', type=str, help='Image file to process.')
  parser.add_argument('--renderer', type=str, help='Renderer.')
  parser.add_argument('--brushstrokes', type=int, help='Maximum brushstrokes.')
  parser.add_argument('--optimal', type=int, help='Optimal transport loss.')
  parser.add_argument('--divides', type=int, help='Max divide patches.')
  parser.add_argument('--output_directory', type=str, help='Directory to output frames and movie to.')

  args3 = parser.parse_args()
  return args3

args2=parse_args();

#get width of input image
im = PIL.Image.open(args2.source_image)
imwidth, imheight = im.size
sys.stdout.write(f"Input image dimensions are {imwidth} by {imheight}\n")
sys.stdout.flush()

device = torch.device("cuda:0" if torch.cuda.is_available() else "cpu")
print('Using device:', device)


# settings
parser = argparse.ArgumentParser(description='STYLIZED NEURAL PAINTING')
args = parser.parse_args(args=[])
args.img_path = args2.source_image #'Scarlett Johansson.png' # path to input photo
args.renderer = args2.renderer #'oilpaintbrush' # [watercolor, markerpen, oilpaintbrush, rectangle]
args.canvas_color = 'black' # [black, white]
args.canvas_size = imwidth # 512 # size of the canvas for stroke rendering'
args.keep_aspect_ratio = True # whether to keep input aspect ratio when saving outputs
args.max_m_strokes = args2.brushstrokes #500 # max number of strokes
args.max_divide = args2.divides #5 # divide an image up-to max_divide x max_divide patches
args.beta_L1 = 1.0 # weight for L1 loss

if args2.optimal == 1:
    args.with_ot_loss = True # set True for improving the convergence by using optimal transportation loss, but will slow-down the speed
else:
    args.with_ot_loss = False # set True for improving the convergence by using optimal transportation loss, but will slow-down the speed

args.beta_ot = 0.1 # weight for optimal transportation loss
args.net_G = 'zou-fusion-net' # renderer architecture
args.renderer_checkpoint_dir = f'./checkpoints_G_{args2.renderer}' # dir to load the pretrained neu-renderer
args.lr = 0.005 # learning rate for stroke searching
#args.output_dir = args2.output_directory #'./output' # dir to save painting results
args.output_dir = './output' # dir to save painting results
args.disable_preview = True # disable cv2.imshow, for running remotely without x-display

"""Define the optimization loop the painter"""

def optimize_x(pt):

    pt._load_checkpoint()
    pt.net_G.eval()

    print('begin drawing...')

    PARAMS = np.zeros([1, 0, pt.rderr.d], np.float32)

    if pt.rderr.canvas_color == 'white':
        CANVAS_tmp = torch.ones([1, 3, 128, 128]).to(device)
    else:
        CANVAS_tmp = torch.zeros([1, 3, 128, 128]).to(device)

    for pt.m_grid in range(1, pt.max_divide + 1):

        pt.img_batch = utils.img2patches(pt.img_, pt.m_grid, pt.net_G.out_size).to(device)
        pt.G_final_pred_canvas = CANVAS_tmp

        pt.initialize_params()
        pt.x_ctt.requires_grad = True
        pt.x_color.requires_grad = True
        pt.x_alpha.requires_grad = True
        utils.set_requires_grad(pt.net_G, False)

        pt.optimizer_x = optim.RMSprop([pt.x_ctt, pt.x_color, pt.x_alpha], lr=pt.lr, centered=True)

        pt.step_id = 0
        for pt.anchor_id in range(0, pt.m_strokes_per_block):
            pt.stroke_sampler(pt.anchor_id)
            iters_per_stroke = int(500 / pt.m_strokes_per_block)
            for i in range(iters_per_stroke):
                pt.G_pred_canvas = CANVAS_tmp

                # update x
                pt.optimizer_x.zero_grad()

                pt.x_ctt.data = torch.clamp(pt.x_ctt.data, 0.1, 1 - 0.1)
                pt.x_color.data = torch.clamp(pt.x_color.data, 0, 1)
                pt.x_alpha.data = torch.clamp(pt.x_alpha.data, 0, 1)

                pt._forward_pass()
                pt._drawing_step_states()
                pt._backward_x()

                pt.x_ctt.data = torch.clamp(pt.x_ctt.data, 0.1, 1 - 0.1)
                pt.x_color.data = torch.clamp(pt.x_color.data, 0, 1)
                pt.x_alpha.data = torch.clamp(pt.x_alpha.data, 0, 1)

                pt.optimizer_x.step()
                pt.step_id += 1

        v = pt._normalize_strokes(pt.x)
        v = pt._shuffle_strokes_and_reshape(v)
        PARAMS = np.concatenate([PARAMS, v], axis=1)
        CANVAS_tmp = pt._render(PARAMS, save_jpgs=False, save_video=False)
        CANVAS_tmp = utils.img2patches(CANVAS_tmp, pt.m_grid + 1, pt.net_G.out_size).to(device)

    pt._save_stroke_params(PARAMS)
    final_rendered_image = pt._render(PARAMS, save_jpgs=False, save_video=True)

    return final_rendered_image

"""Now you can process your image"""

print('ProgressivePainter ...')
pt = ProgressivePainter(args=args)

print('Optimize ...')
final_rendered_image = optimize_x(pt)

"""Check out your animated results at args.output_dir. Before you download that folder, let's first have a look at what the generated painting looks like."""

#plt.imshow(final_rendered_image), plt.title('generated')
#plt.show()
