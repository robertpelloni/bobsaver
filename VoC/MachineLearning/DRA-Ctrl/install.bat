@echo off



echo *** %time% *** Deleting DRA-Ctrl directory if it exists
if exist DRA-Ctrl\. rd /S /Q DRA-Ctrl

echo *** %time% *** Cloning repository
git clone https://github.com/Kunbyte-AI/DRA-Ctrl
cd DRA-Ctrl

echo *** %time% *** Creating venv
python -m venv venv

echo *** %time% *** Activating venv
call venv\scripts\activate.bat

echo *** %time% *** Upgrading pip
python -m pip install -U pip
python -m pip install pip==24.0
pip install wheel==0.45.1
pip install setuptools==65.5.0
pip install ninja==1.11.1.4

echo *** Removing torch from requirements.txt
type requirements.txt | findstr /v torch > stripped.txt
del requirements.txt
ren stripped.txt requirements.txt

echo *** Removing flash-attn from requirements.txt
type requirements.txt | findstr /v flash-attn > stripped.txt
del requirements.txt
ren stripped.txt requirements.txt

echo *** %time% *** Installing requirements
pip install -r requirements.txt
rem pip install https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/deepspeed-0.16.3-cp310-cp310-win_amd64.whl
pip install https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/flash_attn-2.7.4.post1-cp310-cp310-win_amd64.whl

echo *** %time% *** Installing GPU torch
pip uninstall -y torch
pip uninstall -y torch
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.7.0+cu128 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128

rem pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts triton-windows

echo *** %time% *** Downloading models
md ckpts
cd ckpts
git clone https://huggingface.co/hunyuanvideo-community/HunyuanVideo-I2V
git clone https://huggingface.co/Kunbyte/DRA-Ctrl
xcopy DRA-Ctrl\*.*
rd DRA-Ctrl /s/q
cd..

call venv\scripts\deactivate.bat
cd ..
echo *** %time% *** Finished DRA-Ctrl install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause
