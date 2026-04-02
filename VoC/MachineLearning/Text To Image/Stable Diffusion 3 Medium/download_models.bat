@echo off
cls



echo *** VoC - Deleting models directory if it exists...
if exist models\. rd /S /Q models

echo *** VoC - Downloading models...
curl -L -o "models.rar" "https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/models.rar?download=true" -v

echo *** VoC - Extracting models...
7z x models.rar

echo *** VoC - Deleting models.rar...
if exist models.rar del models.rar

echo *** VoC - Models downloaded

echo.
echo *** Scroll up and check for any error messages.  Do not assume the install worked. ***
pause
