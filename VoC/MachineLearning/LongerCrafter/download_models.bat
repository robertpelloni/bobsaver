@echo off
cls
D:
cd "D:\code\Delphi\Chaos\Examples\MachineLearning\LongerCrafter"
echo Downloading models...
echo.

curl -L -o "checkpoints/base_256_v1/model.ckpt" "https://huggingface.co/VideoCrafter/Text2Video-256/resolve/main/model.ckpt" -v
rem old dead URL
rem wget "https://huggingface.co/MoonQiu/LongerCrafter/resolve/main/model.pth" -O "checkpoints/base_256_v1/model.pth" -nc
rem too slow for a 4090 - 44 mins per movie
rem wget "https://huggingface.co/MoonQiu/LongerCrafter/blob/main/model_512.ckpt" -O "checkpoints/base_512_v1/model.pth" -nc
rem OOM on 24 GB GPU
rem wget "https://huggingface.co/VideoCrafter/Text2Video-1024/blob/main/model.ckpt" -O "checkpoints/base_1024_v1/model.pth" -nc

echo.
echo Downloads completed.
echo ***** Scroll up and check for any error messages.  Do not assume the downloads worked. *****
pause