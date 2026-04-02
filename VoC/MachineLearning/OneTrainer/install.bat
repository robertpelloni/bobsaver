@echo off
cls
D:
cd "D:\code\delphi\Chaos\Examples\MachineLearning\OneTrainer"

echo *** VoC - Deleting OneTrainer directory if it exists
if exist OneTrainer. rd /S /Q OneTrainer

echo *** VoC - Deleting .venv directory if it exists
if exist .venv\. rd /S /Q .venv
echo *** VoC - setting up virtual environment
python -m venv .venv
echo *** VoC - activating virtual environment
call .venv\scripts\activate.bat

echo *** VoC - git clone
git clone https://github.com/Nerogar/OneTrainer
cd OneTrainer
rem pull older commit from Jun 8 2024 - this ensures the LoRAs created work with AnimateDiff Prompt Travel
rem git checkout bab144146d096c645a8e74e8c530517f43414931

echo *** VoC - upgrading pip
python.exe -m pip install --upgrade pip

echo *** VoC - installing requirements
rem cd OneTrainer
pip install -r requirements.txt

echo.
echo *** VoC - finished OneTrainer install

echo.
echo *** Scroll up and check for any error messages.  Do not assume the install worked. ***
pause
