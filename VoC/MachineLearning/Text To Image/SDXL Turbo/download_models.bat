@echo off
 
 


echo.
echo Cloning SDXL Turbo models...
echo NOTE: this can take a long time.  Check Task Manager for network activity.
echo.
if exist checkpoints\. rd checkpoints /s/q
if exist sdxl-turbo\. rd sdxl-turbo /s/q
git clone https://huggingface.co/stabilityai/sdxl-turbo
ren sdxl-turbo checkpoints
echo.
echo Downloading models...
echo.
curl -L -o "checkpoints\turbovisionxlSuperFastXLBasedOnNew_alphaV0101Bakedvae.safetensors" https://civitai.com/api/download/models/242733 -v

echo.
echo Downloads completed.
echo ***** Scroll up and check for any error messages.  Do not assume the downloads worked. *****
pause