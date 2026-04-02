@echo off
cls


echo Downloading models...
echo.
if exist models\. rd models /s/q
md models
curl -L -o "models/GFPGANv1.4.pth" "https://huggingface.co/hacksider/deep-live-cam/resolve/main/GFPGANv1.4.pth" -v
curl -L -o "models/inswapper_128_fp16.onnx" "https://huggingface.co/hacksider/deep-live-cam/resolve/main/inswapper_128_fp16.onnx" -v
echo.
echo Downloads completed.
echo ***** Scroll up and check for any error messages.  Do not assume the downloads worked. *****
pause
