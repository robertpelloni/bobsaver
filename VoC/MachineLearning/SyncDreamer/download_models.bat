@echo off
cls
D:
cd "D:\code\Delphi\Chaos\Examples\MachineLearning\SyncDreamer"
echo Downloading required models...
echo.
md ckpt
curl -L -o "ckpt/syncdreamer-pretrain.ckpt" "https://huggingface.co/camenduru/SyncDreamer/resolve/main/syncdreamer-pretrain.ckpt" -v
curl -L -o "ckpt/ViT-L-14.pt" "https://huggingface.co/4eJIoBek/Shap-E/resolve/main/ViT-L-14.pt" -v

echo.
echo Downloads completed.
echo ***** Scroll up and check for any error messages.  Do not assume the downloads worked. *****
pause