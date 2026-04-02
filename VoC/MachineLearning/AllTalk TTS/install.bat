@echo off



echo *** %time% *** Deleting alltalk_tts directory if it exists
if exist alltalk_tts\. rd /S /Q alltalk_tts

echo *** %time% *** Cloning hertz-dev repository
git clone https://github.com/erew123/alltalk_tts
cd alltalk_tts

echo *** %time% *** Installing AllTalk TTS
call atsetup.bat < ..\atsetup.txt

cd ..
echo *** %time% *** Finished alltalk_tts install
echo.
pause
