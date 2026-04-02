@echo off
cls


echo Downloading required models...
echo.
curl -L -o "checkpoints/groundingdino_swint_ogc.pth" "https://huggingface.co/ShilongLiu/GroundingDINO/resolve/main/groundingdino_swint_ogc.pth" -v
curl -L -o "checkpoints/mam_sam_vitb.pth" "https://huggingface.co/shi-labs/Matting-Anything/resolve/main/checkpoints/mam_sam_vitb.pth" -v
echo.
pause
D:
D:

echo.
echo Downloads completed.
echo ***** Scroll up and check for any error messages.  Do not assume the downloads worked. *****
pause