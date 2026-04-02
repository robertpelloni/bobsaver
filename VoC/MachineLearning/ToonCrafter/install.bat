@echo off



cd
echo *** Deleting ToonCrafter directory if it exists
if exist ToonCrafter\. rd /S /Q ToonCrafter

echo *** Cloning ToonCrafter repository
git clone https://github.com/sdbds/ToonCrafter-for-windows
move ToonCrafter-for-windows ToonCrafter
cd ToonCrafter

echo *** Creating venv
python -m venv venv
call venv\scripts\activate.bat

echo *** Installing requirments
python -m pip install --upgrade pip==24.3.1
pip install -r requirements-windows.txt

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

cd..
call ToonCrafter\venv\scripts\deactivate.bat

echo *** Finished ToonCrafter install
echo.
echo *** Scroll up and check for errors.  Do not assume it worked.
pause


