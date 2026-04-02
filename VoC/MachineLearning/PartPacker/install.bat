@echo off



echo *** %time% *** Deleting PartPacker directory if it exists
if exist PartPacker\. rd /S /Q PartPacker

echo *** %time% *** Cloning PartPacker repository
git clone https://github.com/NVlabs/PartPacker
cd PartPacker

rem echo *** %time% *** Removing flash-attn from requirements.txt
rem type requirements.txt | findstr /v flash-attn > stripped.txt
rem del requirements.txt
rem ren stripped.txt requirements.txt

echo *** %time% *** Creating venv
python -m venv venv

echo *** %time% *** Activating venv
call venv\scripts\activate.bat

echo *** %time% *** Installing requirements
python -m pip install --upgrade pip
pip install -r requirements.txt
rem pip install gradio
pip install huggingface_hub[hf_xet]
pip install https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/flash_attn-2.7.4.post1-cp310-cp310-win_amd64.whl

echo *** %time% *** Installing GPU torch
pip uninstall -y torch
pip uninstall -y torch
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.7.0+cu128 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128

pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts triton-windows

echo *** %time% *** Downloading models
md pretrained
curl -L -o "pretrained\vae.pt" "https://huggingface.co/nvidia/PartPacker/resolve/main/vae.pt" -v
curl -L -o "pretrained\flow.pt" "https://huggingface.co/nvidia/PartPacker/resolve/main/flow.pt" -v

call venv\scripts\deactivate.bat
cd ..
echo *** %time% *** Finished PartPacker install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause
