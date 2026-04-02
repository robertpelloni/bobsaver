@echo off
 



curl -L -o "models.rar" "https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/diffusionlightmodels.rar" -v
7z x models.rar
del models.rar

echo.
echo Downloads completed.
echo ***** Scroll up and check for any error messages.  Do not assume the downloads worked. *****
pause
