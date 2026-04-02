@echo off



echo *** %time% *** Deleting TTS-WebUI directory if it exists
if exist TTS-WebUI\. rd /S /Q TTS-WebUI

echo *** %time% *** Cloning repository
git clone https://github.com/rsxdalv/TTS-WebUI
cd TTS-WebUI

copy ..\ffmpeg.exe
copy ..\ffprobe.exe

echo *** %time% *** Creating venv
python -m venv venv

echo *** %time% *** Activating venv
call venv\scripts\activate.bat

echo *** %time% *** Upgrading pip
rem python -m pip install -U pip
rem python -m pip install pip==24.0
python.exe -m pip install --upgrade pip
pip install wheel==0.45.1
pip install setuptools==65.5.0
pip install ninja==1.11.1.4

echo *** Removing triton from requirements.txt
type requirements.txt | findstr /v triton > stripped.txt
del requirements.txt
ren stripped.txt requirements.txt

echo *** %time% *** Installing requirements
pip install -r requirements.txt
rem pip install triton-windows
pip install hf_xet

echo *** %time% *** Installing GPU torch
pip uninstall -y torch
pip uninstall -y torch
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.7.0+cu128 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128

rem echo *** %time% *** Patching numpy
rem pip uninstall -y numpy
rem pip uninstall -y numpy
rem pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts numpy==1.26.4
rem pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts numpy==1.26.4

call venv\scripts\deactivate.bat
cd ..
echo *** %time% *** Finished TTS-WebUI install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause
