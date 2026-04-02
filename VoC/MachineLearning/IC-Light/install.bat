@echo off
cls



echo *** VoC - Deleting IC-Light directory if it exists
if exist IC-Light. rd /S /Q IC-Light

echo *** VoC - git clone IC-Light
git clone https://github.com/lllyasviel/IC-Light

echo *** VoC - Finished IC-Light install

echo.
echo *** Scroll up and check for any error messages.  Do not assume the install worked. ***
pause
