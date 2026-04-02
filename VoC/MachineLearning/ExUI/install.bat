@echo off



echo *** %time% VoC *** Deleting ExUI directory if it exists
if exist ExUI\. rd /S /Q ExUI

echo *** %time% VoC *** Cloning ExUI repository
git clone https://github.com/turboderp/exui
cd ExUI

echo *** %time% VoC *** Creating venv
python -m venv venv

echo *** %time% VoC *** Activating venv
call venv\scripts\activate.bat

echo *** %time% VoC *** Installing requirements
python -m pip install --upgrade pip==24.3.1
pip install -r requirements.txt
pip install tokenizers

echo *** %time% VoC - patching xformers
pip uninstall -y xformers
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts xformers==0.0.30

echo *** %time% VoC - installing GPU torch
pip uninstall -y torch
pip uninstall -y torch
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.7.0+cu128 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128
pip uninstall -y charset-normalizer
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts charset-normalizer==3.3.2

echo *** VoC - patching typing_extensions
pip uninstall -y typing_extensions
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts typing_extensions==4.11.0

echo *** %time% VoC - downloading models
copy ..\download_models.py download_models.py
md models
python download_models.py

call venv\scripts\deactivate.bat
cd ..

echo *** %time% VoC *** Finished ExUI install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause
