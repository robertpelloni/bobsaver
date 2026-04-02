@echo off



cd
echo *** %time% *** Deleting Chain-of-Zoom directory if it exists
if exist Chain-of-Zoom\. rd /S /Q Chain-of-Zoom

echo *** %time% *** Cloning Chain-of-Zoom repository
git clone https://github.com/bryanswkim/Chain-of-Zoom
cd Chain-of-Zoom
copy ..\app.py

echo *** %time% *** Creating venv
python -m venv venv
call venv\scripts\activate.bat

echo *** %time% *** Upgrading pip
python -m pip install -U pip
python -m pip install pip==24.0
pip install wheel==0.45.1
pip install setuptools==65.5.0
pip install ninja==1.11.1.4

echo *** %time% *** Removing nvidia from requirements.txt
type requirements.txt | findstr /v nvidia > stripped.txt
del requirements.txt
ren stripped.txt requirements.txt

echo *** %time% *** Removing triton from requirements.txt
type requirements.txt | findstr /v triton > stripped.txt
del requirements.txt
ren stripped.txt requirements.txt

echo *** %time% *** Installing requirements.txt
pip install -r requirements.txt
pip install gradio==5.32.1

echo *** %time% *** Installing GPU Torch
pip uninstall -y torch
pip uninstall -y torch
pip uninstall -y torch
pip install torch==2.7.0+cu128 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128

pip install triton-windows

echo *** %time% *** Downloading models
cd ckpt

git clone https://huggingface.co/Qwen/Qwen2.5-VL-3B-Instruct
curl -L -o RAM\ram_swin_large_14m.pth https://huggingface.co/spaces/xinyu1205/recognize-anything/resolve/main/ram_swin_large_14m.pth -v
curl -L -o SD3M.rar https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/SD3M.rar -v

echo *** %time% *** Extracting models
..\..\7z x SD3M.rar
del SD3M.rar

call venv\scripts\deactivate.bat
cd..

echo *** %time% *** Finished Chain-of-Zoom install
echo.
echo *** %time% *** Scroll up and check for errors.  Do not assume it worked.
pause
