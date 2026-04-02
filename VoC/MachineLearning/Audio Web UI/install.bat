@echo off
cls
D:


echo *** VoC - Deleting audio-webui directory if it exists
if exist audio-webui\. rd /S /Q audio-webui

echo *** VoC - git clone
git clone https://github.com/gitmylo/audio-webui

echo *** VoC - installing
cd audio-webui
echo | call run.bat

call venv\scripts\activate.bat
pip install soxr

echo.
echo *** VoC - finished Audio Web UI install

pause
