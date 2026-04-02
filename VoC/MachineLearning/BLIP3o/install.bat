@echo off



cd
echo *** Deleting BLIP3o directory if it exists
if exist BLIP3o\. rd /S /Q BLIP3o

echo *** Cloning BLIP3o repository
git clone https://github.com/JiuhaiChen/BLIP3o
cd BLIP3o
git reset --hard 798b206c07c2425269931bbf1f1e5b81875eedbb

echo *** Creating venv
python -m venv venv
call venv\scripts\activate.bat

echo *** Removing deepspeed from requirements.txt
type requirements.txt | findstr /v deepspeed > stripped.txt
del requirements.txt
ren stripped.txt requirements.txt

echo *** Removing flash_attn from requirements.txt
type requirements.txt | findstr /v flash_attn > stripped.txt
del requirements.txt
ren stripped.txt requirements.txt

echo *** Removing xformers from requirements.txt
type requirements.txt | findstr /v xformers > stripped.txt
del requirements.txt
ren stripped.txt requirements.txt

echo *** Upgrading pip
python -m pip install -U pip
python -m pip install pip==24.0
pip install wheel==0.45.1
pip install setuptools==65.5.0

echo *** Installing requirements
pip install -r requirements.txt
pip install -e .
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts xformers==0.0.30
pip install https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/deepspeed-0.16.3-cp310-cp310-win_amd64.whl
pip install https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/flash_attn-2.7.4.post1-cp310-cp310-win_amd64.whl
pip install hf_xet

echo *** Installing GPU Torch
pip uninstall -y torch
pip uninstall -y torch
pip uninstall -y torch
pip install torch==2.7.0+cu128 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128
pip install triton-windows

echo *** Patching pydantic
pip uninstall -y pydantic
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts pydantic==2.5.3

echo *** Patching gradio
pip uninstall -y gradio
pip install gradio==5.31.0

echo *** Downloading models
pip install git-lfs
cd gradio
md models
cd models
git clone https://huggingface.co/BLIP3o/BLIP3o-Model-4B
move BLIP3o-Model-4B BLIP3o4B
rem 8B model needs 26GB VRAM
git clone https://huggingface.co/BLIP3o/BLIP3o-Model-8B
move BLIP3o-Model-8B BLIP3o8B
cd..
cd..

call venv\scripts\deactivate.bat
cd..

echo *** Finished BLIP3o install
echo.
echo *** Scroll up and check for errors.  Do not assume it worked.
pause
