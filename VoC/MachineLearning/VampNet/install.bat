@echo off



if exist VampNet\. rd /S /Q VampNet

echo *** Cloning VampNet repository
git clone --recursive https://github.com/hugofloresgarcia/vampnet
ren vampnet VampNet
cd VampNet

echo *** Creating venv
python -m venv venv
call venv\scripts\activate.bat

echo *** Installing requirements.txt
python -m pip install --upgrade pip==24.3.1
pip install wheel
pip install -e .

echo *** Installing other required packages
pip uninstall -y xformers
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts xformers==0.0.25 --index-url https://download.pytorch.org/whl/cu118
pip uninstall -y torch
pip uninstall -y torch
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.2.2+cu118 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118

echo *** VoC - patching typing_extensions
pip uninstall -y typing_extensions
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts typing_extensions==4.11.0

call venv\scripts\deactivate.bat
cd ..

echo *** Finished VampNet install
echo.


