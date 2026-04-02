@echo off



echo *** Deleting leditsplusplus directory if it exists
if exist leditsplusplus\. rd /S /Q leditsplusplus

echo *** Cloning llama3-s repository
git clone https://huggingface.co/spaces/editing-images/leditsplusplus
cd leditsplusplus

echo *** Creating venv
python -m venv venv
call venv\scripts\activate.bat

echo *** Installing requirments.txt
python -m pip install --upgrade pip==24.3.1
pip install -r requirements.txt

echo *** Installing other required packages
pip install gradio==5.6.0
pip install matplotlib
pip install https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/triton-3.0.0-cp310-cp310-win_amd64.whl

echo *** Installing xformers
pip uninstall -y xformers
rem pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts xformers==0.0.25 --index-url https://download.pytorch.org/whl/cu118
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts xformers==0.0.30

echo *** Installing GPU torch
pip uninstall -y torch
pip uninstall -y torch
rem pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.2.2+cu118 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.7.0+cu128 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128

echo *** %time% *** Patching typing-extensions
pip uninstall -y typing-extensions
pip uninstall -y typing-extensions
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts typing-extensions==4.12.2

echo *** %time% *** Patching huggingface_hub
pip uninstall -y huggingface_hub
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts huggingface_hub==0.25.2


rem echo *** Downloading models
rem rd checkpoints /s/q
rem if not exist checkpoints\. md checkpoints
rem ..\wget "https://huggingface.co/jiachenli-ucsb/T2V-Turbo-VC2/resolve/main/unet_lora.pt" -O "checkpoints\unet_lora.pt" -nc --no-check-certificate
rem ..\wget "https://huggingface.co/VideoCrafter/VideoCrafter2/resolve/main/model.ckpt" -O "checkpoints\model.ckpt" -nc --no-check-certificate

call venv\scripts\deactivate.bat

echo *** Finished LEDITS++ install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause
