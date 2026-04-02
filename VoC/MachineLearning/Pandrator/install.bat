@echo off



cd
echo *** Deleting Pandrator directory if it exists
if exist Pandrator\. rd /S /Q Pandrator

echo *** Cloning Pandrator repository
git clone https://github.com/lukaszliniewicz/Pandrator.git
cd Pandrator

echo *** Creating venv
python -m venv venv
call venv\scripts\activate.bat

echo *** Installing requirments
python -m pip install --upgrade pip==24.3.1
pip install -r requirements.txt

cd..

echo *** Installing XTTS API server
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts xtts-api-server -r xtts-api-server-requirements.txt

echo *** Installing Silero API server
pip install silero-api-server

echo *** Installing GPU Torch
pip uninstall -y torch
pip uninstall -y torch
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.2.1+cu118 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118

echo *** VoC - patching typing_extensions
pip uninstall -y typing_extensions
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts typing_extensions==4.11.0

call Pandrator\venv\scripts\deactivate.bat

echo *** Finished Pandrator install
echo.
echo *** Scroll up and check for errors.  Do not assume it worked.
pause


