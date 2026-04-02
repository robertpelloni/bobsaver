@echo off
cls
D:
cd "D:\code\delphi\Chaos\Examples\MachineLearning\Enfugue\"

echo *** VoC - Deleting enfugue-server directory if it exists
if exist enfugue-server\. rd /S /Q enfugue-server

echo *** VoC - Downloading zip files ...
echo.
curl -L -o "enfugue-server-0.2.3-win-cuda-x86_64.zip.001" "https://github.com/painebenjamin/app.enfugue.ai/releases/download/0.2.3/enfugue-server-0.2.3-win-cuda-x86_64.zip.001" -v
curl -L -o "enfugue-server-0.2.3-win-cuda-x86_64.zip.002" "https://github.com/painebenjamin/app.enfugue.ai/releases/download/0.2.3/enfugue-server-0.2.3-win-cuda-x86_64.zip.002" -v
echo.

echo *** VoC - Unzipping ...
7z x enfugue-server-0.2.3-win-cuda-x86_64.zip.001
echo.

echo *** VoC - Deleting zip files ...
echo.
del enfugue-server-0.2.3-win-cuda-x86_64.zip.001
del enfugue-server-0.2.3-win-cuda-x86_64.zip.002
echo.

echo *** VoC - Install finished.

echo.
echo *** Scroll up and check for any error messages.  Do not assume the install worked. ***
pause
