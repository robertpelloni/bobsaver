@echo off
 



rd models /s/q
if not exist models\. md models
curl -L -o "models\drag_nuwa_svd.pth" "https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/drag.pth" -v

echo.
echo Downloads completed.
echo ***** Scroll up and check for any error messages.  Do not assume the downloads worked. *****
pause