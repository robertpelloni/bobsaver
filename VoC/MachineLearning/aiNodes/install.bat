@echo off
cls
D:
cd "D:\code\Delphi\Chaos\Examples\MachineLearning\aiNodes"

echo *** VoC - Deleting ainodes-engine directory if it exists
if exist ainodes-engine\. rd /S /Q ainodes-engine

echo *** VoC - git clone
git clone https://www.github.com/XmYx/ainodes-engine

echo *** VoC - installing
cd ainodes-engine
call setup_ainodes.bat

echo.
echo *** VoC - finished aiNodes install

echo.
echo *** Scroll up and check for any error messages.  Do not assume the install worked. ***
pause
