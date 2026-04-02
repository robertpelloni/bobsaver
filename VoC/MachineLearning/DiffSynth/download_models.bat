@echo off
cls



echo Started at %date% %time%
echo.

rem echo Deleting existing models folder if it exists...
rem if exist models\. rd models /s/q

echo.
echo Downloading models...
echo.

if not exist models\. md models
if not exist models\AnimateDiff\. md models\AnimateDiff
if not exist models\Annotators\. md models\Annotators
if not exist models\BeautifulPrompt\. md models\BeautifulPrompt
if not exist models\ControlNet\. md models\ControlNet
if not exist models\lora\. md models\lora
if not exist models\RIFE\. md models\RIFE
if not exist models\stable_diffusion\. md models\stable_diffusion
if not exist models\stable_diffusion_xl\. md models\stable_diffusion_xl
if not exist models\stable_diffusion_xl_turbo\. md models\stable_diffusion_xl_turbo
if not exist models\textual_inversion\. md models\textual_inversion
if not exist models\translator\. md models\translator

rem sdxl_text_to_image
rem models/stable_diffusion_xl/bluePencilXL_v200.safetensors`: [link](https://civitai.com/api/download/models/245614?type=Model&format=SafeTensor&size=pruned&fp=fp16
curl -L -o "models\stable_diffusion_xl\bluePencilXL_v200.safetensors" "https://civitai.com/api/download/models/245614?type=Model&format=SafeTensor&size=pruned&fp=fp16" -v

rem sdxl_turbo
rem models/stable_diffusion_xl_turbo/sd_xl_turbo_1.0_fp16.safetensors`: [link](https://huggingface.co/stabilityai/sdxl-turbo/resolve/main/sd_xl_turbo_1.0_fp16.safetensors
curl -L -o "models/stable_diffusion_xl_turbo/sd_xl_turbo_1.0_fp16.safetensors" "https://huggingface.co/stabilityai/sdxl-turbo/resolve/main/sd_xl_turbo_1.0_fp16.safetensors" -v

rem sd_video_render
rem models/stable_diffusion/dreamshaper_8.safetensors`: [link](https://civitai.com/api/download/models/128713?type=Model&format=SafeTensor&size=pruned&fp=fp16
rem models/ControlNet/control_v11f1p_sd15_depth.pth`: [link](https://huggingface.co/lllyasviel/ControlNet-v1-1/resolve/main/control_v11f1p_sd15_depth.pth
rem models/ControlNet/control_v11p_sd15_softedge.pth`: [link](https://huggingface.co/lllyasviel/ControlNet-v1-1/resolve/main/control_v11p_sd15_softedge.pth
rem models/Annotators/dpt_hybrid-midas-501f0c75.pt`: [link](https://huggingface.co/lllyasviel/Annotators/resolve/main/dpt_hybrid-midas-501f0c75.pt
rem models/Annotators/ControlNetHED.pth`: [link](https://huggingface.co/lllyasviel/Annotators/resolve/main/ControlNetHED.pth
rem models/RIFE/flownet.pkl`: [link](https://drive.google.com/file/d/1APIzVeI-4ZZCEuIRE1m6WYfSCaOsi_7_/view?usp=sharing
curl -L -o "models/stable_diffusion/dreamshaper_8.safetensors" "https://civitai.com/api/download/models/128713?type=Model&format=SafeTensor&size=pruned&fp=fp16" -v
curl -L -o "models/ControlNet/control_v11f1p_sd15_depth.pth" "https://huggingface.co/lllyasviel/ControlNet-v1-1/resolve/main/control_v11f1p_sd15_depth.pth" -v
curl -L -o "models/ControlNet/control_v11p_sd15_softedge.pth" "https://huggingface.co/lllyasviel/ControlNet-v1-1/resolve/main/control_v11p_sd15_softedge.pth" -v
curl -L -o "models/Annotators/dpt_hybrid-midas-501f0c75.pt" "https://huggingface.co/lllyasviel/Annotators/resolve/main/dpt_hybrid-midas-501f0c75.pt" -v
curl -L -o "models/Annotators/ControlNetHED.pth" "https://huggingface.co/lllyasviel/Annotators/resolve/main/ControlNetHED.pth" -v
curl -L -o "models/RIFE/flownet.pkl" "https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/flownet.pkl?download=true" -v

rem sd_toon_shading
rem models/stable_diffusion/flat2DAnimerge_v45Sharp.safetensors`: [link](https://civitai.com/api/download/models/266360?type=Model&format=SafeTensor&size=pruned&fp=fp16
rem models/AnimateDiff/mm_sd_v15_v2.ckpt`: [link](https://huggingface.co/guoyww/animatediff/resolve/main/mm_sd_v15_v2.ckpt
rem models/ControlNet/control_v11p_sd15_lineart.pth`: [link](https://huggingface.co/lllyasviel/ControlNet-v1-1/resolve/main/control_v11p_sd15_lineart.pth
rem models/ControlNet/control_v11f1e_sd15_tile.pth`: [link](https://huggingface.co/lllyasviel/ControlNet-v1-1/resolve/main/control_v11f1e_sd15_tile.pth
rem models/Annotators/sk_model.pth`: [link](https://huggingface.co/lllyasviel/Annotators/resolve/main/sk_model.pth
rem models/Annotators/sk_model2.pth`: [link](https://huggingface.co/lllyasviel/Annotators/resolve/main/sk_model2.pth
rem models/textual_inversion/verybadimagenegative_v1.3.pt`: [link](https://civitai.com/api/download/models/25820?type=Model&format=PickleTensor&size=full&fp=fp16
rem models/RIFE/flownet.pkl`: [link](https://drive.google.com/file/d/1APIzVeI-4ZZCEuIRE1m6WYfSCaOsi_7_/view?usp=sharing
curl -L -o "models/stable_diffusion/flat2DAnimerge_v45Sharp.safetensors" "https://civitai.com/api/download/models/266360?type=Model&format=SafeTensor&size=pruned&fp=fp16" -v
curl -L -o "models/AnimateDiff/mm_sd_v15_v2.ckpt" "https://huggingface.co/guoyww/animatediff/resolve/main/mm_sd_v15_v2.ckpt" -v
curl -L -o "models/ControlNet/control_v11p_sd15_lineart.pth" "https://huggingface.co/lllyasviel/ControlNet-v1-1/resolve/main/control_v11p_sd15_lineart.pth" -v
curl -L -o "models/ControlNet/control_v11f1e_sd15_tile.pth" "https://huggingface.co/lllyasviel/ControlNet-v1-1/resolve/main/control_v11f1e_sd15_tile.pth" -v
curl -L -o "models/Annotators/sk_model.pth" "https://huggingface.co/lllyasviel/Annotators/resolve/main/sk_model.pth" -v
curl -L -o "models/Annotators/sk_model2.pth" "https://huggingface.co/lllyasviel/Annotators/resolve/main/sk_model2.pth" -v
curl -L -o "models/textual_inversion/verybadimagenegative_v1.3.pt" "https://civitai.com/api/download/models/25820?type=Model&format=PickleTensor&size=full&fp=fp16" -v
curl -L -o "models/RIFE/flownet.pkl" "https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/flownet.pkl?download=true" -v

rem sd_text_to_video
rem models/stable_diffusion/dreamshaper_8.safetensors`: [link](https://civitai.com/api/download/models/128713?type=Model&format=SafeTensor&size=pruned&fp=fp16
rem models/AnimateDiff/mm_sd_v15_v2.ckpt`: [link](https://huggingface.co/guoyww/animatediff/resolve/main/mm_sd_v15_v2.ckpt
rem models/RIFE/flownet.pkl`: [link](https://drive.google.com/file/d/1APIzVeI-4ZZCEuIRE1m6WYfSCaOsi_7_/view?usp=sharing
curl -L -o "models/stable_diffusion/dreamshaper_8.safetensors" "https://civitai.com/api/download/models/128713?type=Model&format=SafeTensor&size=pruned&fp=fp16" -v
curl -L -o "models/AnimateDiff/mm_sd_v15_v2.ckpt" "https://huggingface.co/guoyww/animatediff/resolve/main/mm_sd_v15_v2.ckpt" -v
curl -L -o "models/RIFE/flownet.pkl" "https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/flownet.pkl?download=true" -v

rem sd_text_to_image
rem models/stable_diffusion/aingdiffusion_v12.safetensors`: [link](https://civitai.com/api/download/models/229575?type=Model&format=SafeTensor&size=full&fp=fp16
rem models/ControlNet/control_v11p_sd15_lineart.pth`: [link](https://huggingface.co/lllyasviel/ControlNet-v1-1/resolve/main/control_v11p_sd15_lineart.pth
rem models/ControlNet/control_v11f1e_sd15_tile.pth`: [link](https://huggingface.co/lllyasviel/ControlNet-v1-1/resolve/main/control_v11f1e_sd15_tile.pth
rem models/Annotators/sk_model.pth`: [link](https://huggingface.co/lllyasviel/Annotators/resolve/main/sk_model.pth
rem models/Annotators/sk_model2.pth`: [link](https://huggingface.co/lllyasviel/Annotators/resolve/main/sk_model2.pth
curl -L -o "models/stable_diffusion/aingdiffusion_v12.safetensors" "https://civitai.com/api/download/models/229575?type=Model&format=SafeTensor&size=full&fp=fp16" -v
curl -L -o "models/ControlNet/control_v11p_sd15_lineart.pth" "https://huggingface.co/lllyasviel/ControlNet-v1-1/resolve/main/control_v11p_sd15_lineart.pth" -v
curl -L -o "models/ControlNet/control_v11f1e_sd15_tile.pth" "https://huggingface.co/lllyasviel/ControlNet-v1-1/resolve/main/control_v11f1e_sd15_tile.pth" -v
curl -L -o "models/Annotators/sk_model.pth" "https://huggingface.co/lllyasviel/Annotators/resolve/main/sk_model.pth" -v
curl -L -o "models/Annotators/sk_model2.pth" "https://huggingface.co/lllyasviel/Annotators/resolve/main/sk_model2.pth" -v
curl -L -o "models/textual_inversion/verybadimagenegative_v1.3.pt" "https://civitai.com/api/download/models/25820?type=Model&format=PickleTensor&size=full&fp=fp16" -v

rem sd_prompt_refining
rem models/stable_diffusion_xl/sd_xl_base_1.0.safetensors`: [link](https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0/resolve/main/sd_xl_base_1.0.safetensors
rem models/BeautifulPrompt/pai-bloom-1b1-text2prompt-sd/`: [link](https://huggingface.co/alibaba-pai/pai-bloom-1b1-text2prompt-sd
rem models/translator/opus-mt-zh-en/`: [link](https://huggingface.co/Helsinki-NLP/opus-mt-en-zh
curl -L -o "models/stable_diffusion_xl/sd_xl_base_1.0.safetensors" "https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0/resolve/main/sd_xl_base_1.0.safetensors" -v
rem models/BeautifulPrompt/pai-bloom-1b1-text2prompt-sd/`: [link](https://huggingface.co/alibaba-pai/pai-bloom-1b1-text2prompt-sd
rem models/translator/opus-mt-zh-en/`: [link](
cd models
cd BeautifulPrompt
echo ***
echo *** NOTE: Git cloning can take a while with minimal stats.  Check Task Manager network activity if you think it has hung.
echo ***
git clone https://huggingface.co/alibaba-pai/pai-bloom-1b1-text2prompt-sd
cd ..
cd translator
echo ***
echo *** NOTE: Git cloning can take a while with minimal stats.  Check Task Manager network activity if you think it has hung.
echo ***
git clone https://huggingface.co/Helsinki-NLP/opus-mt-en-zh
cd ..
cd ..
rem diffusion_toon_shading
rem models/stable_diffusion/aingdiffusion_v12.safetensors`: [link](https://civitai.com/api/download/models/229575
rem models/AnimateDiff/mm_sd_v15_v2.ckpt`: [link](https://huggingface.co/guoyww/animatediff/resolve/main/mm_sd_v15_v2.ckpt
rem models/ControlNet/control_v11p_sd15_lineart.pth`: [link](https://huggingface.co/lllyasviel/ControlNet-v1-1/resolve/main/control_v11p_sd15_lineart.pth
rem models/ControlNet/control_v11f1e_sd15_tile.pth`: [link](https://huggingface.co/lllyasviel/ControlNet-v1-1/resolve/main/control_v11f1e_sd15_tile.pth
rem models/Annotators/sk_model.pth`: [link](https://huggingface.co/lllyasviel/Annotators/resolve/main/sk_model.pth
rem models/Annotators/sk_model2.pth`: [link](https://huggingface.co/lllyasviel/Annotators/resolve/main/sk_model2.pth
rem models/textual_inversion/verybadimagenegative_v1.3.pt`: [link](https://civitai.com/api/download/models/25820?type=Model&format=PickleTensor&size=full&fp=fp16
curl -L -o "models/stable_diffusion/aingdiffusion_v12.safetensors" "https://civitai.com/api/download/models/229575?type=Model&format=SafeTensor&size=full&fp=fp16" -v
curl -L -o "models/AnimateDiff/mm_sd_v15_v2.ckpt" "https://huggingface.co/guoyww/animatediff/resolve/main/mm_sd_v15_v2.ckpt" -v
curl -L -o "models/ControlNet/control_v11p_sd15_lineart.pth" "https://huggingface.co/lllyasviel/ControlNet-v1-1/resolve/main/control_v11p_sd15_lineart.pth" -v
curl -L -o "models/ControlNet/control_v11f1e_sd15_tile.pth" "https://huggingface.co/lllyasviel/ControlNet-v1-1/resolve/main/control_v11f1e_sd15_tile.pth" -v
curl -L -o "models/Annotators/sk_model.pth" "https://huggingface.co/lllyasviel/Annotators/resolve/main/sk_model.pth" -v
curl -L -o "models/Annotators/sk_model2.pth" "https://huggingface.co/lllyasviel/Annotators/resolve/main/sk_model2.pth" -v
curl -L -o "models/textual_inversion/verybadimagenegative_v1.3.pt" "https://civitai.com/api/download/models/25820?type=Model&format=PickleTensor&size=full&fp=fp16" -v

echo Finished at %date% %time%
echo.

echo Done
pause
