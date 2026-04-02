@echo off
cls
D:
cd "D:\VoC_Systems\FRESCO\"

echo *** VoC - Deleting FRESCO directory if it exists
if exist FRESCO. rd /S /Q FRESCO

echo *** VoC - Deleting .venv directory if it exists
if exist .venv\. rd /S /Q .venv
echo *** VoC - setting up virtual environment
python -m venv .venv
echo *** VoC - activating virtual environment
call .venv\scripts\activate.bat

echo *** VoC - upgrading pip
python.exe -m pip install --upgrade pip

echo *** VoC - installing requirements
python -m pip install --upgrade pip==24.3.1
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts wheel==0.43.0
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts diffusers[torch]==0.19.3
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts transformers==4.39.3
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts opencv-python==4.9.0.80
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts einops==0.7.0
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts matplotlib==3.8.4
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts timm==0.9.16
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts av==12.0.0
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts basicsr==1.4.2
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts numba==0.57.0
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts imageio-ffmpeg==0.4.9
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts gradio==3.44.4
pip uninstall -y torch
rem pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.2.1+cu118 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.7.0+cu128 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128

echo *** VoC - git clone FRESCO
git clone https://github.com/williamyang1991/FRESCO
cd FRESCO
echo *** VoC - running FRESCO install.py
python install.py

echo *** VoC - Patching numpy
pip uninstall -y numpy
pip uninstall -y numpy
pip uninstall -y numpy
pip uninstall -y numpy
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts numpy==1.23.5

echo *** VoC - patching typing_extensions
pip uninstall -y typing_extensions
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts typing_extensions==4.11.0

echo *** VoC - patching huggingface-hub
pip uninstall -y huggingface-hub
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts huggingface-hub==0.25.0
pip install hf_xet

echo *** VoC - Finished FRESCO install

echo.
echo *** Scroll up and check for any error messages.  Do not assume the install worked. ***
pause
