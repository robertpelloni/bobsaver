@echo off
cls


echo Downloading required models...
echo.
curl -L -o "ckpts/bigcolor/EG_011.ckpt" "https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/EG_011.ckpt" -v
curl -L -o "ckpts/bigcolor/EG_EMA_011.ckpt" "https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/EG_EMA_011.ckpt" -v
curl -L -o "ckpts/bigcolor/args.pkl" "https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/args.pkl" -v
curl -L -o "pretrained/D_256.pth" "https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/D_256.pth" -v
curl -L -o "pretrained/config.pickle" "https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/config.pickle" -v
curl -L -o "pretrained/G_ema_256.pth" "https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/G_ema_256.pth" -v
curl -L -o "pretrained/vgg16.pickle" "https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/vgg16.pickle" -v

echo.
echo Downloads completed.
echo ***** Scroll up and check for any error messages.  Do not assume the downloads worked. *****
pause
