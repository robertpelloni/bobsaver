@echo off




cd
echo *** Deleting MimicBrush directory if it exists
if exist MimicBrush\. rd /S /Q MimicBrush

echo *** Cloning MimicBrush repository
git clone https://github.com/ali-vilab/MimicBrush
copy inference.yaml .\MimicBrush\configs\inference.yaml /y
cd MimicBrush


echo *** Creating venv
python -m venv venv
call venv\scripts\activate.bat

echo *** Installing MimicBrush requirements
python -m pip install --upgrade pip==24.3.1
pip install -r requirements.txt

echo *** VoC - patching xformers
pip uninstall -y xformers
rem pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts xformers==0.0.25 --index-url https://download.pytorch.org/whl/cu118
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts xformers==0.0.30

echo *** VoC - installing GPU torch
pip uninstall -y torch
pip uninstall -y torch
rem pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.2.1+cu118 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.7.0+cu128 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128

echo *** VoC - patching typing_extensions
pip uninstall -y typing_extensions
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts typing_extensions==4.11.0

echo *** VoC - downlaoding models
copy ..\download_models.py download_models.py
python download_models.py

call venv\scripts\deactivate.bat
cd..

echo *** Finished MimicBrush install
echo.
echo *** Scroll up and check for errors.  Do not assume it worked.
pause


