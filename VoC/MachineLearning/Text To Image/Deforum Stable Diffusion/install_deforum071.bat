@echo off



echo *** %time% *** Deleting deforum-stable-diffusion directory-071 if it exists
if exist deforum-stable-diffusion\. rd /S /Q deforum-stable-diffusion
if exist deforum-stable-diffusion-071\. rd /S /Q deforum-stable-diffusion-071

echo *** %time% *** Cloning repository
git clone https://github.com/deforum/deforum-stable-diffusion
move deforum-stable-diffusion deforum-stable-diffusion-071
cd deforum-stable-diffusion-071
copy ..\ffmpeg.exe
rem copy ..\ffprobe.exe

echo *** %time% *** Creating venv
python -m venv venv

echo *** %time% *** Activating venv
call venv\scripts\activate.bat

echo *** %time% *** Upgrading pip
python.exe -m pip install --upgrade pip
pip install wheel==0.45.1
pip install setuptools==65.5.0
pip install ninja==1.11.1.4

echo *** %time% *** Installing requirements
python install_requirements.py
pip install pytorch-lightning==2.6.1
pip install git-lfs==1.6
pip install clip==0.2.0

echo *** %time% *** Installing GPU torch
pip uninstall -y torch
pip uninstall -y torch
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.7.0+cu128 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128

echo *** %time% *** Patching numpy
pip uninstall -y numpy
pip install numpy==1.26.4

echo *** %time% *** Downloading models
md openai
cd openai
git clone https://huggingface.co/openai/clip-vit-large-patch14
cd..

call venv\scripts\deactivate.bat
cd ..
echo *** %time% *** Finished Deforum 0.7.1 install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause
