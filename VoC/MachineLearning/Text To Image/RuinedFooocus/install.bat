@echo off
cls



echo *** VoC - Attempting to download RuinedFooocus_main_2.0.0.win64.7z
curl -L -o "RuinedFooocus.7z" "https://github.com/runew0lf/RuinedFooocus/releases/download/Release-2.0.0/RuinedFooocus_main_2.0.0.win64.7z" -v

if errorlevel 1 (
   echo curl error detected
) ELSE (
    goto skip0
)

del RuinedFooocus.zip
echo .
rem echo Unable to download Fooocus_win64_2-5-0.7z
echo Unable to download RuinedFooocus_main_2.0.0.win64.7z
echo RuinedFooocus has probably been updated and the zip filename was changed.
echo .
echo Please let Softology know and he will update the installer.
echo You could also politely request the dev uses a standard name for all releases.
echo .
goto end

:skip0
echo *** VoC - Deleting RuinedFooocus directory if it exists
if exist RuinedFooocus\. rd /S /Q RuinedFooocus

echo *** VoC - Extracting downloaded zip
7z x RuinedFooocus.7z
move RuinedFooocus_main_2.0.0.win64 RuinedFooocus

echo *** VoC - Deleting downloaded 7z
del RuinedFooocus.7z

echo *** VoC - Downloading FLUX Kontext model
curl -L -o "RuinedFooocus\RuinedFooocus\models\checkpoints\flux1KontextFp8And_fp8Scaled.safetensors" "https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/flux1KontextFp8And_fp8Scaled.safetensors" -v

echo *** VoC - finished RuinedFooocus install
echo.
echo *** Scroll up and check for any error messages.  Do not assume the install worked. ***

:end
pause

