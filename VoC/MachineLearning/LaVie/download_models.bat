@echo off
echo Started: %date% %time% 



if exist pretrained_models\. rd pretrained_models /s /q
git clone https://huggingface.co/YaohuiW/LaVie
move LaVie pretrained_models
cd pretrained_models
git clone https://huggingface.co/CompVis/stable-diffusion-v1-4
git clone https://huggingface.co/stabilityai/stable-diffusion-x4-upscaler
echo Finished: %date% %time% 

echo.
echo Downloads completed.
echo ***** Scroll up and check for any error messages.  Do not assume the downloads worked. *****
pause
D:
