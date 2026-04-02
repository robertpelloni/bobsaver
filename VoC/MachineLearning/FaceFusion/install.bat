@echo off



echo *** %time% *** Deleting FaceFusion directory if it exists
if exist FaceFusion\. rd /S /Q FaceFusion

echo *** %time% *** Downloading v3.0.0 zip
md FaceFusion
cd FaceFusion
curl -L -o 3.0.0.zip https://github.com/facefusion/facefusion/archive/refs/tags/3.0.0.zip -v

echo *** %time% *** Extracting v3.0.0 zip
..\7z x 3.0.0.zip
del 3.0.0.zip
move facefusion-3.0.0 FaceFusion
cd FaceFusion

copy ..\..\ffmpeg.exe
copy ..\..\ffprobe.exe

echo *** %time% VoC *** Creating venv
python -m venv venv

echo *** %time% VoC *** Activating venv
call venv\scripts\activate.bat

echo *** %time% VoC *** Updating pip
python.exe -m pip install --upgrade pip

echo *** VoC - Installing FaceFusion
python install.py --onnxruntime cuda --skip-conda 

echo *** VoC - Installing GPU torch
rem pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.4.1+cu121 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121
pip install torch==2.7.0+cu128 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128

echo *** VoC - Patching numpy
pip uninstall -y numpy
pip uninstall -y numpy
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts numpy==1.26.4

echo *** VoC - patching typing_extensions
pip uninstall -y typing_extensions
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts typing_extensions==4.11.0

echo *** VoC - patching pydantic
pip uninstall -y pydantic
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts pydantic==2.10.6

echo *** VoC - patching huggingface_hub
pip uninstall -y huggingface_hub
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts huggingface_hub==0.34.3

echo *** VoC - patching to latest code
curl -L -o master.zip https://github.com/facefusion/facefusion/archive/refs/heads/master.zip -v
..\..\7z x master.zip
del master.zip
xcopy facefusion-master\*.* /s/r/y
rd facefusion-master /s/q

cd..
cd..
echo *** %time% *** Finished FaceFusion install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause
