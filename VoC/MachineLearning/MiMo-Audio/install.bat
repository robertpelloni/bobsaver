@echo off



echo *** %time% *** Deleting MiMo-Audio directory if it exists
if exist MiMo-Audio\. rd /S /Q MiMo-Audio

echo *** %time% *** Cloning repository
git clone https://github.com/XiaomiMiMo/MiMo-Audio
cd MiMo-Audio

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

echo *** Removing scipy from requirements.txt
type requirements.txt | findstr /v scipy > stripped.txt
del requirements.txt
ren stripped.txt requirements.txt

echo *** Removing triton from requirements.txt
type requirements.txt | findstr /v triton > stripped.txt
del requirements.txt
ren stripped.txt requirements.txt

echo *** %time% *** Installing requirements
pip install -r requirements.txt
rem pip install scipy
pip install triton-windows==3.3.0.post19
pip install https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/flash_attn-2.7.4.post1-cp310-cp310-win_amd64.whl

echo *** %time% *** Installing GPU torch
pip uninstall -y torch
pip uninstall -y torch
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.7.0+cu128 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128

echo *** %time% *** Downloading models
pip install huggingface-hub
pip install hf_xet
hf download XiaomiMiMo/MiMo-Audio-Tokenizer --local-dir ./models/MiMo-Audio-Tokenizer
hf download XiaomiMiMo/MiMo-Audio-7B-Base --local-dir ./models/MiMo-Audio-7B-Base
hf download XiaomiMiMo/MiMo-Audio-7B-Instruct --local-dir ./models/MiMo-Audio-7B-Instruct

call venv\scripts\deactivate.bat
cd ..
echo *** %time% *** Finished MiMo-Audio install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause
