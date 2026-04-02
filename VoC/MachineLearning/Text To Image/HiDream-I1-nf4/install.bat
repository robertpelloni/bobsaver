@echo off



if exist HiDream-I1-nf4\. rd /S /Q HiDream-I1-nf4

echo *** %time% *** Cloning HiDream-I1-nf4 repository
git clone https://github.com/hykilpikonna/HiDream-I1-nf4
cd HiDream-I1-nf4

echo *** Creating venv
python -m venv venv
call venv\scripts\activate.bat

echo *** %time% *** Installing requirements
python -m pip install --upgrade pip==24.3.1
pip install wheel==0.45.1
pip install setuptools==65.5.0

rem pip install -r requirements.txt
pip install diffusers==0.32.1
pip install transformers==4.47.1
pip install einops==0.7.0
pip install accelerate==1.2.1

pip uninstall -y torch
pip uninstall -y torch
pip uninstall -y torch
pip install https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/flash_attn-2.7.4.post1-cp310-cp310-win_amd64.whl
pip install torch==2.7.0+cu128 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128
pip install gradio==5.25.2
pip install triton-windows==3.2.0.post17
pip install sentencepiece==0.2.0
pip install optimum==1.24.0
pip install auto-gptq==0.7.1
pip install bitsandbytes==0.45.5

cd ..
echo *** %time% VoC *** Finished HiDream-I1-nf4 install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause
