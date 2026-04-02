@echo off




echo *** %time% *** Downloading example workflows
md Examples
if exist Examples\Outpainting\. rd Examples\Outpainting /s/q
md Examples\Outpainting

cd Examples\Outpainting
curl -L -o "ComfyUI_Outpainting.rar" "https://softology.pro/ComfyUI_Outpainting/ComfyUI_Outpainting.rar" -v
..\..\7z x ComfyUI_Outpainting.rar
del ComfyUI_Outpainting.rar
cd..
cd..

rem skip model downloads?
if "%1"=="" goto download_models
echo *** VoC - skipping model downloads
goto skip_models
:download_models

:skip_models
echo *** %time% *** Finished Outpainting install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause

rem Outpainting workflows
