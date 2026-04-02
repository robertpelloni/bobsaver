@echo off
cls
D:
cd "D:\code\Delphi\Chaos\Examples\MachineLearning\LLaMA-Factory\"

echo *** VoC - Deleting LLaMA-Factory directory if it exists
if exist LLaMA-Factory. rd /S /Q LLaMA-Factory

echo *** VoC - git clone
git clone https://github.com/hiyouga/LLaMA-Factory

echo.
echo *** VoC - finished OneTrainer install

echo.
echo *** Scroll up and check for any error messages.  Do not assume the install worked. ***
pause
