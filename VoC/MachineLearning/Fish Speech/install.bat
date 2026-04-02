@echo off




echo *** %time% VoC *** Deleting fish-speech directory if it exists
if exist fish-speech\. rd /S /Q fish-speech

echo *** %time% VoC *** Cloning fish-speech repository
git clone https://github.com/fishaudio/fish-speech

copy API_FLAGS.txt fish-speech\API_FLAGS.txt 

cd fish-speech

echo *** %time% VoC *** Creating venv
call install_env.bat

echo *** %time% VoC *** Downloading models
huggingface-cli download fishaudio/fish-speech-1.5 --local-dir checkpoints/fish-speech-1.5

rem echo *** VoC - patching xformers
rem pip uninstall -y xformers
rem pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts xformers==0.0.25 --index-url https://download.pytorch.org/whl/cu118

rem echo *** VoC - Installing GPU torch
rem pip uninstall -y torch
rem pip uninstall -y torch
rem pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.4.0+cu118 torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/cu118

cd ..
echo *** %time% VoC *** Finished fish-speech install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause
