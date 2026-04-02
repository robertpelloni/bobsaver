@echo off
echo *** VoC - Deleting FlexGen directory if it exists
if exist FlexGen\. rd /S /Q FlexGen
echo *** VoC - Cloning repository
git clone https://github.com/FMInference/FlexGen.git
cd FlexGen
git checkout 9d888e5e3e6d78d6d4e1fdda7c8af508b889aeae
echo *** VoC - setting up virtual environment
python -m venv .venv
echo *** VoC - activating virtual environment
call .venv\scripts\activate.bat
echo *** VoC - updating pip
python.exe -m pip install --upgrade pip
echo *** VoC - installing requirements
pip install -e .
echo *** VoC - installing wheel
pip install wheel
echo *** VoC - installing GPU torch
pip uninstall -y torch
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==1.13.1+cu116 torchvision==0.14.1+cu116 torchaudio==0.13.1+cu116 --extra-index-url https://download.pytorch.org/whl/cu116
echo *** VoC - finished FlexGen install




