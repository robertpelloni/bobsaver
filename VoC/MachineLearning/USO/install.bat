@echo off



echo *** %time% *** Deleting USO directory if it exists
if exist USO\. rd /S /Q USO

echo *** %time% *** Cloning repository
git clone https://github.com/bytedance/USO
cd USO

echo *** %time% *** Creating venv
python -m venv venv

echo *** %time% *** Activating venv
call venv\scripts\activate.bat

echo *** %time% *** Removing deepspeed from requirements.txt
type requirements.txt | findstr /v deepspeed > stripped.txt
del requirements.txt
ren stripped.txt requirements.txt

echo *** %time% *** Installing requirements
python -m pip install --upgrade pip
pip install -r requirements.txt
pip install https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/deepspeed-0.16.3-cp310-cp310-win_amd64.whl?download=true
pip install hf_xet

echo *** %time% *** Installing GPU torch
pip uninstall -y torch
pip uninstall -y torch
pip uninstall -y torch
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.7.0+cu128 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128

echo *** %time% *** Downloading models
cd weights
md FLUX.1-dev
curl -L -o "FLUX.1-dev\ae.safetensors" "https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/ae.sft" -v
md FLUX.1-Krea-dev
curl -L -o "FLUX.1-Krea-dev\flux1-krea-dev.safetensors" "https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/flux1-krea-dev.safetensors" -v
md FLUX-dev-fp8
curl -L -o "FLUX-dev-fp8\flux1-dev-fp8.safetensors" "https://huggingface.co/Kijai/flux-fp8/resolve/main/flux1-dev-fp8.safetensors" -v

cd..
copy ..\downloader.py
python downloader.py

call venv\scripts\deactivate.bat
cd ..
echo *** %time% *** Finished USO install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause
