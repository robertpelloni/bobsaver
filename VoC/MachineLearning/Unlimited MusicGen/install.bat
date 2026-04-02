@echo off
cls
D:
cd "D:\code\Delphi\Chaos\Examples\MachineLearning\Unlimited MusicGen"

echo *** VoC - Deleting audiocraft directory if it exists
if exist audiocraft\. rd /S /Q audiocraft

echo *** VoC - Deleting .venv directory if it exists
if exist .venv\. rd /S /Q .venv
echo *** VoC - setting up virtual environment
python -m venv .venv
echo *** VoC - activating virtual environment
call .venv\scripts\activate.bat

echo *** VoC - git clone
git clone https://github.com/Oncorporation/audiocraft

echo *** VoC - upgrading pip
python.exe -m pip install --upgrade pip

echo *** VoC - installing requirements
cd audiocraft

pip install -r requirements.txt
pip install -U git+https://git@github.com/facebookresearch/audiocraft#egg=audiocraft

echo *** VoC - patching xformers
pip uninstall -y xformers
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts xformers==0.0.25 --index-url https://download.pytorch.org/whl/cu118

echo *** VoC - patching gradio
pip uninstall -y gradio
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts gradio==3.28.3

echo *** VoC - installing GPU torch
pip uninstall -y torch
pip uninstall -y torch
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.2.1+cu118 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118

echo *** VoC - patching typing_extensions
pip uninstall -y typing_extensions
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts typing_extensions==4.11.0

echo.
echo *** VoC - finished Unlimited MusicGen install

echo.
echo *** Scroll up and check for any error messages.  Do not assume the install worked. ***
pause
