@echo off
cls
D:
cd "D:\code\Delphi\Chaos\Examples\MachineLearning\Bark Web UI"

echo *** VoC - Deleting bark-gui directory if it exists
if exist bark-gui\. rd /S /Q bark-gui

echo *** VoC - Deleting .venv directory if it exists
if exist .venv\. rd /S /Q .venv
echo *** VoC - setting up virtual environment
python -m venv .venv
echo *** VoC - activating virtual environment
call .venv\scripts\activate.bat

echo *** VoC - git clone
git clone https://github.com/C0untFloyd/bark-gui

echo *** VoC - upgrading pip
python.exe -m pip install --upgrade pip

echo *** VoC - installing requirements
cd bark-gui
rem pip install .
rem pip install gradio
rem pip install soundfile
pip install -r requirements.txt

echo *** VoC - installing GPU torch
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.0.0+cu118 torchaudio==2.0.0+cu118 --index-url https://download.pytorch.org/whl/cu118
echo *** VoC - reinstalling typing-extensions
pip uninstall -y typing-extensions
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts typing_extensions==4.7.1

echo *** VoC - patching typing_extensions
pip uninstall -y typing_extensions
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts typing_extensions==4.11.0

echo.
echo *** VoC - finished Bark Web UI install

echo.
echo *** Scroll up and check for any error messages.  Do not assume the install worked. ***
pause
