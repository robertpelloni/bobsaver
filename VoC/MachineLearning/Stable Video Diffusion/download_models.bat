@echo off
echo Started: %date% %time% 



rem if exist checkpoints\. rd checkpoints /s /q
rem md checkpoints
if not exist checkpoints\. md checkpoints

curl -L -o "checkpoints\svd.safetensors" "https://huggingface.co/stabilityai/stable-video-diffusion-img2vid/resolve/main/svd.safetensors" -v
curl -L -o "checkpoints\svd_image_decoder.safetensors" "https://huggingface.co/stabilityai/stable-video-diffusion-img2vid/resolve/main/svd_image_decoder.safetensors" -v
curl -L -o "checkpoints\svd_xt.safetensors" "https://huggingface.co/stabilityai/stable-video-diffusion-img2vid-xt/resolve/main/svd_xt.safetensors" -v
curl -L -o "checkpoints\svd_xt_image_decoder.safetensors" "https://huggingface.co/stabilityai/stable-video-diffusion-img2vid-xt/resolve/main/svd_xt_image_decoder.safetensors" -v

echo Finished: %date% %time% 

echo.
echo Downloads completed.
echo ***** Scroll up and check for any error messages.  Do not assume the downloads worked. *****
pause
D:
