@echo off




echo *** %time% *** Deleting Examples\ZImageBase directory if it exists
if exist Examples\ZImageBase\. rd /S /Q Examples\ZImageBase

echo *** %time% *** Downloading example workflows
md Examples\ZImageBase
curl -L -o "Examples\ZImageBase\Z-Image_Base.json" "https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/Z-Image_Base.json" -v

echo *** %time% *** Finished Z-Image Base install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause

rem Text-to-Image
