@echo off



if exist MoMo\. rd /S /Q MoMo

echo *** Cloning MoMo repository
git clone https://github.com/JHLew/MoMo
cd MoMo

echo *** Creating venv
python -m venv venv
call venv\scripts\activate.bat

echo *** Removing triton from requirements.txt
type requirements.txt | findstr /v triton > stripped.txt
del requirements.txt
ren stripped.txt requirements.txt

echo *** Installing requirements.txt
python -m pip install --upgrade pip==24.3.1
pip install -r requirements.txt

echo *** Installing other required packages
pip uninstall -y xformers
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts xformers==0.0.25 --index-url https://download.pytorch.org/whl/cu118
pip uninstall -y torch
pip uninstall -y torch
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.2.1+cu118 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118

echo *** patching typing_extensions
pip uninstall -y typing_extensions
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts typing_extensions==4.11.0

echo *** patching huggingface_hub
pip uninstall -y huggingface_hub
pip install huggingface_hub==0.23.4

echo *** patching numpy
pip uninstall -y numpy
pip uninstall -y numpy
pip install numpy==1.26.4

echo *** patching tqdm
pip uninstall -y tqdm
pip install tqdm==4.66.4

call venv\scripts\deactivate.bat
cd ..

echo *** Downloading models
md ckpts
curl -L -o "MoMo\experiments.rar" "https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/momo_models.rar" -v

echo *** Extracting models
cd MoMo
..\7z x experiments.rar
del experiments.rar
cd..

echo *** Finished MoMo install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause

