@echo off
cls



echo Started at %date% %time%
echo.

echo Deleting existing pretrained folder if it exists...
if exist pretrained\. rd pretrained /s/q
if not exist pretrained\. md pretrained

echo.
echo Downloading models...
echo.
curl -L -o "pretrained\model.safetensors" "https://huggingface.co/ashawkey/LGM/resolve/main/model.safetensors" -v
curl -L -o "pretrained\model_fp16.safetensors" "https://huggingface.co/ashawkey/LGM/resolve/main/model_fp16.safetensors" -v

echo Finished at %date% %time%
echo.

echo Done
pause