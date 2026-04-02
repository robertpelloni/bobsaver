@echo off




echo *** %time% *** Deleting Examples\FLUX directory if it exists
if exist Examples\FLUX\. rd /S /Q Examples\FLUX

rem skip model downloads?
if "%1"=="" goto download_models
echo *** VoC - skipping model downloads
goto skip_models
:download_models

:skip_models
echo *** %time% *** Downloading example workflows
md Examples\FLUX
curl -L -o "Examples\FLUX\FD3.rar" "https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/FD3.rar" -v
cd Examples\FLUX
..\..\7z.exe x FD3.rar
del FD3.rar
cd..
cd..

echo *** %time% *** Finished FLUX install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause

rem Inpainting, Outpainting, Text-to-Image, FLUX Kontext Image Editing
