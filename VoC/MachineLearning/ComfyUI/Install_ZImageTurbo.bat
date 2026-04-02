@echo off




echo *** %time% *** Deleting Examples\ZImageTurbo directory if it exists
if exist Examples\ZImageTurbo\. rd /S /Q Examples\ZImageTurbo

echo *** %time% *** Downloading example workflows
md Examples\ZImageTurbo
curl -L -o "Examples\ZImageTurbo\Z-Image_Turbo.json" "https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/Z-Image_Turbo.json" -v

echo *** %time% *** Finished Z-Image Turbo install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause

rem Text-to-Image
