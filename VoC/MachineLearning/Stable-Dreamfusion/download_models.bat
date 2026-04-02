@echo off
cls


echo Downloading required models...
echo.
curl -L -o "pretrained/zero123/105000.ckpt" "https://huggingface.co/cvlab/zero123-weights/resolve/main/105000.ckpt" -v

echo.
echo Downloads completed.
echo ***** Scroll up and check for any error messages.  Do not assume the downloads worked. *****
pause