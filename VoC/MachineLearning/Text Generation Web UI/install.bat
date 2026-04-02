@echo off


echo *** %time% *** Deleting text-generation-webui directory if it exists
if exist text-generation-webui\. rd /S /Q text-generation-webui

echo *** %time% *** Cloning text-generation-webui repository
git clone https://github.com/oobabooga/text-generation-webui
cd text-generation-webui
rem April 12th 2025 - pre v3
git checkout 038a01258136ea305b9ed56bc5967ebf2ea2265c

echo *** Creating venv
python -m venv venv
call venv\scripts\activate.bat

echo *** %time% *** Installing requirements
python -m pip install --upgrade pip==24.3.1
pip install wheel
pip install setuptools
pip install -r requirements.txt
rem pip install -r requirements\full\requirements.txt
pip uninstall -y xformers
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts xformers==0.0.30
pip uninstall -y transformers
pip install transformers==4.56.1

echo *** %time% - Installing GPU torch
pip uninstall -y torch
pip uninstall -y torch
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.7.0+cu128 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128

echo *** %time% - Patching numpy
pip uninstall -y numpy
pip uninstall -y numpy
pip uninstall -y numpy
pip install numpy==1.26.0

cd ..
echo *** %time% VoC *** Finished text-generation-webui install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause
