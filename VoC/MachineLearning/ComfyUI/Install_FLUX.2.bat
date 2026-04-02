@echo off




echo *** %time% *** Deleting Examples\FLUX.2 directory if it exists
if exist Examples\FLUX.2\. rd /S /Q Examples\FLUX.2

echo *** %time% *** Downloading example workflows
md Examples\FLUX.2
curl -L -o "Examples\FLUX.2\ScarlettJohansson1024x1024.png" "https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/ScarlettJohansson1024x1024.png" -v
curl -L -o "Examples\FLUX.2\FLUX.2.json" "https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/FLUX.2.json" -v
curl -L -o "Examples\FLUX.2\FLUX.2_input_image.json" "https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/FLUX.2_input_image.json" -v
cd..

echo *** %time% *** Finished FLUX.2 install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause

rem Image-to-Image, Text-to-Image
