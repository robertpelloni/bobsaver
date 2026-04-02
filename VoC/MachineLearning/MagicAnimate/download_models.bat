@echo off
cls



echo Deleting pretrained_models directory if it exists...

if exist pretrained_models\. rd pretrained_models /s/q
md pretrained_models
cd pretrained_models

echo.
echo Cloning https://huggingface.co/runwayml/stable-diffusion-v1-5 ...
echo This can take a while.  Check Task Manager for network activity.
rem git clone https://huggingface.co/runwayml/stable-diffusion-v1-5
git clone https://huggingface.co/stable-diffusion-v1-5/stable-diffusion-v1-5

echo.
echo Cloning https://huggingface.co/stabilityai/sd-vae-ft-mse ...
echo This can take a while.  Check Task Manager for network activity.
git clone https://huggingface.co/stabilityai/sd-vae-ft-mse

echo.
echo Cloning https://huggingface.co/zcxu-eric/MagicAnimate ...
echo This can take a while.  Check Task Manager for network activity.
git clone https://huggingface.co/zcxu-eric/MagicAnimate

rem wget "https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/VideoReTalking-checkpoints-001.zip" -O "VideoReTalking-checkpoints-001.zip"

echo.
echo Downloads completed.
echo ***** Scroll up and check for any error messages.  Do not assume the downloads worked. *****
pause
