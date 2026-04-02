@echo off




rem the idea with this is to run after every example workflow install to make sure torch, triton and sageattention are at the latest versions
echo *** VoC - Patching ComfyUI after workflow install to make sure latest pytorch, triton and sageattention are installed
echo *** VoC - activating virtual environment
call .venv\scripts\activate.bat

echo *** VoC - updating pip
python.exe -m pip install --upgrade pip

echo *** Updating GPU torch
pip uninstall -y torch
pip uninstall -y torch
pip uninstall -y torch
pip install torch==2.7.0+cu128 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128

echo *** VoC - Patching triton and sage-attention
pip uninstall -y triton-windows
pip install triton-windows
pip uninstall -y sageattention
pip install https://github.com/woct0rdho/SageAttention/releases/download/v2.1.1-windows/sageattention-2.1.1+cu128torch2.7.0-cp310-cp310-win_amd64.whl
cd..

echo *** VoC - finished ComfyUI patching
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause
