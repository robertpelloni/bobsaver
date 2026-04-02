@echo off
cls


echo Downloading required models...
echo.
if exist models.zip del models.zip
if exist models\. rd models /s/q
md models

curl -L -o "models\79999_iter.pth" "https://github.com/Hillobar/Rope/releases/download/Sapphire/79999_iter.pth" -v
curl -L -o "models\codeformer_fp16.onnx" "https://github.com/Hillobar/Rope/releases/download/Sapphire/codeformer_fp16.onnx" -v
curl -L -o "models\det_10g.onnx" "https://github.com/Hillobar/Rope/releases/download/Sapphire/det_10g.onnx" -v
curl -L -o "models\epoch_16_best.ckpt" "https://github.com/Hillobar/Rope/releases/download/Sapphire/epoch_16_best.ckpt" -v
curl -L -o "models\faceparser_fp16.onnx" "https://github.com/Hillobar/Rope/releases/download/Sapphire/faceparser_fp16.onnx" -v
curl -L -o "models\GFPGANv1.4.onnx" "https://github.com/Hillobar/Rope/releases/download/Sapphire/GFPGANv1.4.onnx" -v
curl -L -o "models\GPEN-BFR-256.onnx" "https://github.com/Hillobar/Rope/releases/download/Sapphire/GPEN-BFR-256.onnx" -v
curl -L -o "models\GPEN-BFR-512.onnx" "https://github.com/Hillobar/Rope/releases/download/Sapphire/GPEN-BFR-512.onnx" -v
curl -L -o "models\inswapper_128.fp16.onnx" "https://github.com/Hillobar/Rope/releases/download/Sapphire/inswapper_128.fp16.onnx" -v
curl -L -o "models\occluder.onnx" "https://github.com/Hillobar/Rope/releases/download/Sapphire/occluder.onnx" -v
curl -L -o "models\rd64-uni-refined.pth" "https://github.com/Hillobar/Rope/releases/download/Sapphire/rd64-uni-refined.pth" -v
curl -L -o "models\res50.onnx" "https://github.com/Hillobar/Rope/releases/download/Sapphire/res50.onnx" -v
curl -L -o "models\scrfd_2.5g_bnkps.onnx" "https://github.com/Hillobar/Rope/releases/download/Sapphire/scrfd_2.5g_bnkps.onnx" -v
curl -L -o "models\w600k_r50.onnx" "https://github.com/Hillobar/Rope/releases/download/Sapphire/w600k_r50.onnx" -v
curl -L -o "models\yoloface_8n.onnx" "https://github.com/Hillobar/Rope/releases/download/Sapphire/yoloface_8n.onnx" -v

echo.
echo Downloads completed.
echo ***** Scroll up and check for any error messages.  Do not assume the downloads worked. *****
pause
