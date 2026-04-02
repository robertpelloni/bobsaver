@echo off
cls



echo *** VoC - Deleting stable-diffusion-3.5-large directory if it exists...
if exist stable-diffusion-3.5-large\. rd /S /Q stable-diffusion-3.5-large

echo *** VoC - Downloading model...
curl -L -o "SD35L.part1.rar" "https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/SD35L.part1.rar" -v
curl -L -o "SD35L.part2.rar" "https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/SD35L.part2.rar" -v
curl -L -o "SD35L.part3.rar" "https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/SD35L.part3.rar" -v

echo *** VoC - Extracting model...
7z x SD35L.part1.rar

echo *** VoC - Deleting model rar files...
if exist SD35L.part1.rar del SD35L.part1.rar
if exist SD35L.part2.rar del SD35L.part2.rar
if exist SD35L.part3.rar del SD35L.part3.rar

echo *** VoC - Model downloaded

echo.
echo *** Scroll up and check for any error messages.  Do not assume the install worked. ***
pause
