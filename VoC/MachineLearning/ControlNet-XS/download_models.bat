@echo off
cls


echo Downloading models...
echo.
curl -L -o "sd21_encD_canny_14m.ckpt" "https://huggingface.co/CVL-Heidelberg/ControlNet-XS/resolve/main/sd21_encD_canny_14m.ckpt" -v
curl -L -o "sd21_encD_depth_14m.ckpt" "https://huggingface.co/CVL-Heidelberg/ControlNet-XS/resolve/main/sd21_encD_depth_14m.ckpt" -v
curl -L -o "sdxl_encD_canny_48m.safetensors" "https://huggingface.co/CVL-Heidelberg/ControlNet-XS/resolve/main/sdxl_encD_canny_48m.safetensors" -v
curl -L -o "sdxl_encD_depth_48m.safetensors" "https://huggingface.co/CVL-Heidelberg/ControlNet-XS/resolve/main/sdxl_encD_depth_48m.safetensors" -v
curl -L -o "sd_xl_base_1.0_0.9vae.safetensors" "https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0/resolve/main/sd_xl_base_1.0_0.9vae.safetensors" -v
curl -L -o "v2-1_512-ema-pruned.ckpt" "https://huggingface.co/stabilityai/stable-diffusion-2-1-base/resolve/main/v2-1_512-ema-pruned.ckpt" -v

echo.
echo Downloads completed.
echo ***** Scroll up and check for any error messages.  Do not assume the downloads worked. *****
pause
