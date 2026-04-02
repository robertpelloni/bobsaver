@echo off
cls



echo Started at %date% %time%
echo.

echo Deleting existing checkpoint folder if it exists...
if exist checkpoints\. rd checkpoints /s/q

echo.
echo Cloning SD v1.5 models...
echo NOTE: this can take a long time.  Check Task Manager for network activity.
echo.
md checkpoints
cd checkpoints
rem git clone https://huggingface.co/runwayml/stable-diffusion-v1-5
git clone https://huggingface.co/stable-diffusion-v1-5/stable-diffusion-v1-5

echo.
echo Downloading DreamShaper model...
echo.
md base_models
cd base_models
curl -L -o "dreamshaper_8.safetensors" "https://civitai.com/api/download/models/128713?type=Model&format=SafeTensor&size=pruned&fp=fp16" -v
cd ..

echo.
echo Downloading motion models...
echo.
md unet_temporal
cd unet_temporal
curl -L -o "motion_checkpoint_less_motion.ckpt" "https://huggingface.co/crishhh/animatediff_controlnet/resolve/main/motion_checkpoint_less_motion.ckpt" -v
curl -L -o "motion_checkpoint_more_motion.ckpt" "https://huggingface.co/crishhh/animatediff_controlnet/resolve/main/motion_checkpoint_more_motion.ckpt" -v
cd..
echo.

echo.
echo Downloading controlnet model...
echo.
md controlnet
cd controlnet
curl -L -o "controlnet_checkpoint.ckpt" "https://huggingface.co/crishhh/animatediff_controlnet/resolve/main/controlnet_checkpoint.ckpt" -v
cd ..
echo.

echo Finished at %date% %time%

echo.
echo Downloads completed.
echo ***** Scroll up and check for any error messages.  Do not assume the downloads worked. *****
pause
