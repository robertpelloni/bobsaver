@echo off




cd
echo *** Deleting VideoLLaMA2 directory if it exists
if exist VideoLLaMA2\. rd /S /Q VideoLLaMA2

echo *** Cloning VideoLLaMA2 repository
git clone https://github.com/DAMO-NLP-SG/VideoLLaMA2
cd VideoLLaMA2

echo *** Creating venv
python -m venv venv
call venv\scripts\activate.bat

echo *** Installing requirements before VideoLLaMA2 requirements
python -m pip install --upgrade pip==24.3.1
pip install wheel
pip install packaging
pip install setuptools
pip install torch

echo *** Removing deepspeed from requirements.txt
type requirements.txt | findstr /v deepspeed > stripped.txt
del requirements.txt
ren stripped.txt requirements.txt

echo *** Removing bitsandbytes from requirements.txt
type requirements.txt | findstr /v bitsandbytes > stripped.txt
del requirements.txt
ren stripped.txt requirements.txt

echo *** Installing VideoLLaMA2 requirements
pip install -r requirements.txt
rem pip install -e .
rem pip install flash-attn --no-build-isolation

pip install https://softology.pro/wheels/deepspeed-0.12.6-py3-none-any.whl
pip install https://softology.pro/wheels/bitsandbytes-0.41.1-py3-none-win_amd64.whl
rem pip install https://softology.pro/wheels/flash_attn-2.4.2+cu121torch2.1cxx11abiFALSE-cp310-cp310-win_amd64.whl

echo *** VoC - patching xformers
pip uninstall -y xformers
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts xformers==0.0.25 --index-url https://download.pytorch.org/whl/cu118

echo *** VoC - installing GPU torch
pip uninstall -y torch
pip uninstall -y torch
pip uninstall -y torch
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.2.1+cu118 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118

echo *** VoC - patching typing_extensions
pip uninstall -y typing_extensions
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts typing_extensions==4.11.0

call venv\scripts\deactivate.bat
cd..

echo *** Finished VideoLLaMA2 install
echo.
echo *** Scroll up and check for errors.  Do not assume it worked.
pause


