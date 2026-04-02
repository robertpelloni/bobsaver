@echo off
cls
D:
cd "D:\code\Delphi\Chaos\Examples\MachineLearning\StreamingT2V\"

echo *** VoC - Deleting previous StreamingT2V directory if it exists
if exist StreamingT2V. rd /S /Q StreamingT2V

echo *** VoC - Deleting .venv directory if it exists
if exist .venv\. rd /S /Q .venv
echo *** VoC - setting up virtual environment
python -m venv .venv
echo *** VoC - activating virtual environment
call .venv\scripts\activate.bat

echo *** VoC - git clone
git clone https://github.com/Picsart-AI-Research/StreamingT2V
cd StreamingT2V

echo *** VoC - upgrading pip
python.exe -m pip install --upgrade pip
rem python -m pip install -U pip
rem python -m pip install pip==24.0

echo *** VoC - installing requirements
pip install matplotlib==3.9.0
pip install -r requirements.txt

echo *** VoC - git clone modelscope
cd t2v_enhanced
git clone https://github.com/modelscope/modelscope modelscopetmp
move modelscopetmp\modelscope modelscope
rd modelscopetmp /s/q

echo *** VoC - updating xformers
pip uninstall -y xformers
rem pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts xformers==0.0.25 --index-url https://download.pytorch.org/whl/cu118
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts xformers==0.0.30

echo *** VoC - updating GPU torch
pip uninstall -y torch
pip uninstall -y torch
pip uninstall -y torch
rem pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.2.2+cu118 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.7.0+cu128 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128

echo *** VoC - patching datasets
pip uninstall -y datasets
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts datasets==2.18.0

echo *** VoC - patching numpy
pip uninstall -y numpy
pip uninstall -y numpy
pip uninstall -y numpy
pip uninstall -y numpy
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts numpy==1.26.4

echo *** VoC - patching typing_extensions
pip uninstall -y typing_extensions
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts typing_extensions==4.11.0

echo *** VoC - downloading streaming_t2v.ckpt model
md checkpoints
cd checkpoints
curl -L -o streaming_t2v.ckpt https://huggingface.co/PAIR/StreamingT2V/resolve/main/streaming_t2v.ckpt -v

echo.
echo *** VoC - finished StreamingT2V install

echo.
echo *** Scroll up and check for any error messages.  Do not assume the install worked. ***
pause