@echo off




rem skip model downloads?
if "%1"=="" goto download_models
echo *** VoC - skipping model downloads
goto skip_models
:download_models

:skip_models
echo *** %time% *** Downloading example workflow
md Examples\StableDiffusion3.5
curl -L -o "Examples\StableDiffusion3.5\StableDiffusion3.5.json" "https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/StableDiffusion3.5.json" -v

echo *** %time% *** Finished SD 3.5 install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause

rem Text-to-Image
