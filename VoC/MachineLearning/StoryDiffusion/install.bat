@echo off
cls



echo *** VoC - Deleting StoryDiffusion directory if it exists
if exist StoryDiffusion. rd /S /Q StoryDiffusion

echo *** VoC - git clone
git clone https://github.com/HVision-NKU/StoryDiffusion

echo.
echo *** VoC - finished StoryDiffusion Infinity install

echo.
echo *** Scroll up and check for any error messages.  Do not assume the install worked. ***
pause
