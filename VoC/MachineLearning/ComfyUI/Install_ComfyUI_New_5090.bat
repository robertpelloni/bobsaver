@echo off




echo *** VoC - ComfyUI install running under
cd

echo *** VoC - Installing ComfyUI for detected 50xx GPU
echo *** VoC - Deleting ComfyUI directory if it exists
if exist ComfyUI\. rd /S /Q ComfyUI

echo *** VoC - Deleting Examples directory if it exists
if exist Examples\. rd /S /Q Examples
md Examples
cd Examples
copy ..\7z.exe
copy ..\7z.dll
cd..

echo *** VoC - python --version
python --version

echo *** VoC - Cloning repository
git clone https://github.com/comfyanonymous/ComfyUI
cd ComfyUI

rem If you want to roll back to a previous commit
rem echo *** Rolling back to July 1st commit 772de7c00653fc3a825762f555e836d071a4dc80
rem git reset --hard 772de7c00653fc3a825762f555e836d071a4dc80
rem git clean -df

copy ..\ffmpeg.exe

echo *** VoC - Cloning ComfyUI Manager
cd custom_nodes
if exist ComfyUI-Manager\. rd /S /Q ComfyUI-Manager
git clone https://github.com/ltdrdata/ComfyUI-Manager.git
if [%1]==[rollback] goto rollback
goto skip
:rollback
echo *** VoC - Rolling ComfyUI Manager back to v3.37.1
rem if this is not done, newer manager >3.37.1 has security checks that stop installs working inside older comfy versions
rem so if user uses the upodate button to rollback comfy then the manager will not install missing nodes
cd ComfyUI-Manager
git checkout 3.37.1
cd..
:skip
cd..

echo *** VoC - setting up virtual environment
python -m venv .venv

echo *** VoC - activating virtual environment
call .venv\scripts\activate.bat

echo *** VoC - updating pip
python.exe -m pip install --upgrade pip

rem echo *** Installing xformers
rem pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts xformers==0.0.30
rem patch 1/3 for pytorch 2.10.0 support
rem for now xformers 0.0.34 seems to cause problems with some nodes on 5090 GPUs
rem pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts xformers==0.0.34

echo *** Installing GPU torch
rem pip install torch==2.7.0+cu128 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128
rem patch 2/3 for pytorch 2.10.0 support
pip install torch==2.10.0+cu128 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128

echo *** VoC - installing requirements.txt
pip install -r requirements.txt
echo *** VoC - installing triton-windows
pip install -U triton-windows
echo *** VoC - installing sageattention
rem pip install https://github.com/woct0rdho/SageAttention/releases/download/v2.1.1-windows/sageattention-2.1.1+cu128torch2.7.0-cp310-cp310-win_amd64.whl
rem patch 3/3 for pytorch 2.10.0 support
pip install https://github.com/woct0rdho/SageAttention/releases/download/v2.2.0-windows.post4/sageattention-2.2.0+cu128torch2.9.0andhigher.post4-cp39-abi3-win_amd64.whl
echo *** VoC - installing hf_xet
pip install hf_xet
cd..

echo *** VoC - downloading v1-5-pruned-emaonly-fp16.safetensors
if exist ComfyUI\models\checkpoints\v1-5-pruned-emaonly-fp16.safetensors del ComfyUI\models\checkpoints\v1-5-pruned-emaonly-fp16.safetensors
curl -L -o "ComfyUI\models\checkpoints\v1-5-pruned-emaonly-fp16.safetensors" "https://huggingface.co/Comfy-Org/stable-diffusion-v1-5-archive/resolve/main/v1-5-pruned-emaonly-fp16.safetensors" -v

echo *** VoC - finished ComfyUI install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause
