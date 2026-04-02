@echo off



echo *** %time% *** Deleting FancyVideo directory if it exists
if exist FancyVideo\. rd /S /Q FancyVideo

echo *** %time% *** Cloning FancyVideo repository
git clone https://github.com/360CVGroup/FancyVideo
cd FancyVideo
copy scripts\demo.py demo.py

echo *** Removing triton from requirements.txt
type requirements.txt | findstr /v triton > stripped.txt
del requirements.txt
ren stripped.txt requirements.txt

echo *** Removing deepspeed from requirements.txt
type requirements.txt | findstr /v deepspeed > stripped.txt
del requirements.txt
ren stripped.txt requirements.txt

echo *** %time% *** Creating venv
python -m venv venv

echo *** %time% *** Activating venv
call venv\scripts\activate.bat

echo *** %time% *** Installing requirements
python -m pip install --upgrade pip
pip install wheel
pip install setuptools
pip install -r requirements.txt
pip install https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/deepspeed-0.16.3-cp310-cp310-win_amd64.whl

echo *** %time% *** Patching xformers
pip uninstall -y xformers
rem pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts xformers==0.0.27.post2 --index-url https://download.pytorch.org/whl/cu121
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts xformers==0.0.30

echo *** %time% *** Installing GPU torch
pip uninstall -y torch
pip uninstall -y torch
rem pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.4.0+cu121 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.7.0+cu128 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128

echo *** VoC - patching typing_extensions
pip uninstall -y typing_extensions
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts typing_extensions==4.11.0

echo *** VoC - huggingface
pip uninstall -y huggingface-hub
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts huggingface-hub==0.25.0

echo *** VoC - patching numpy
pip uninstall -y numpy
pip uninstall -y numpy
pip uninstall -y numpy
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts numpy==1.26.4

echo *** %time% *** Downloading models
git lfs install
md resources
md temp
cd temp
git clone https://huggingface.co/qihoo360/FancyVideo
move FancyVideo\resources\models ..\resources
cd..
rd /s/q temp

md temp
cd temp
rem git clone https://huggingface.co/runwayml/stable-diffusion-v1-5
git clone https://huggingface.co/stable-diffusion-v1-5/stable-diffusion-v1-5
move stable-diffusion-v1-5 ..\resources\models
cd..
rd /s/q temp

call venv\scripts\deactivate.bat
cd ..
echo *** %time% *** Finished FancyVideo install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause
