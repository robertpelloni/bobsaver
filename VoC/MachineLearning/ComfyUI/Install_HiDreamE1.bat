@echo off




echo *** %time% *** Deleting Examples\HiDream-E1 directory if it exists
if exist Examples\HiDream-E1\. rd /S /Q Examples\HiDream-E1

rem skip model downloads?
if "%1"=="" goto download_models
echo *** VoC - skipping model downloads
goto skip_models
:download_models

:skip_models
echo *** %time% *** Downloading example workflows
md Examples\HiDream-E1
curl -L -o "Examples\HiDream-E1\HiDream.rar" "https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/HiDream-E1.rar" -v
cd Examples\HiDream-E1
..\..\7z.exe x HiDream.rar
del HiDream.rar
cd..
cd..

echo *** %time% *** Finished HiDream-E1 install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause

rem Text-to-Image, Image Editing
