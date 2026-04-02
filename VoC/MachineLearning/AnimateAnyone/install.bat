@echo off



echo *** %time% VoC *** Deleting AnimateAnyone directory if it exists
if exist AnimateAnyone\. rd /S /Q AnimateAnyone
if exist Moore-AnimateAnyone\. rd /S /Q Moore-AnimateAnyone

echo *** %time% VoC *** Cloning ExUI repository
git clone https://github.com/MooreThreads/Moore-AnimateAnyone
ren Moore-AnimateAnyone AnimateAnyone
cd AnimateAnyone

echo *** %time% VoC *** Cloning OpenSeeFace repository
git clone https://github.com/emilianavt/OpenSeeFace.git 

echo *** %time% VoC *** Creating venv
python -m venv venv

echo *** %time% VoC *** Activating venv
call venv\scripts\activate.bat

echo *** %time% VoC *** Installing requirements
python -m pip install -U pip
python -m pip install pip==24.0
pip install -r requirements.txt

echo *** %time% VoC - patching xformers
pip uninstall -y xformers
rem pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts xformers==0.0.27 --index-url https://download.pytorch.org/whl/cu118
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts xformers==0.0.30

echo *** %time% VoC - installing GPU torch
pip uninstall -y torch
pip uninstall -y torch
rem pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.3.1+cu118 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.7.0+cu128 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128

pip uninstall -y charset-normalizer
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts charset-normalizer==3.3.2

echo *** VoC - patching typing_extensions
pip uninstall -y typing_extensions
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts typing_extensions==4.11.0

echo *** %time% VoC - Downloading weights
python tools/download_weights.py

call venv\scripts\deactivate.bat
cd ..

echo *** %time% VoC *** Finished AnimateAnyone install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause
