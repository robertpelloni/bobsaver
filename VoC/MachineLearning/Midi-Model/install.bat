@echo off




cd
echo *** Deleting Midi-Model directory if it exists
if exist Midi-Model\. rd /S /Q Midi-Model

echo *** Downloading app
curl -L -o "app-gpu.zip" "https://github.com/SkyTNT/midi-model/releases/download/v1.1.0/app-gpu.zip" -v

echo *** Extracting app
7z x app-gpu.zip -oMidi-Model
del app-gpu.zip

echo *** Finished Midi-Model install
echo.
echo *** Scroll up and check for errors.  Do not assume it worked.
pause
