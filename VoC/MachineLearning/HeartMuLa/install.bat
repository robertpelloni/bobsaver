@echo off



echo *** %time% *** Deleting heartlib directory if it exists
if exist heartlib\. rd /S /Q heartlib

echo *** %time% *** Cloning repository
git clone https://github.com/HeartMuLa/heartlib.git
cd heartlib
copy ..\app.py

echo *** %time% *** Creating venv
python -m venv venv

echo *** %time% *** Activating venv
call venv\scripts\activate.bat

echo *** %time% *** Upgrading pip
python.exe -m pip install --upgrade pip
pip install wheel==0.45.1
pip install setuptools==65.5.0
pip install ninja==1.11.1.4

echo *** %time% *** Installing requirements
pip install -e .
pip install spaces

echo *** %time% *** Installing GPU torch
pip uninstall -y torch
pip uninstall -y torch
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.7.0+cu128 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128

echo *** %time% *** Installing more requirements
pip install torchtext
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts triton-windows==3.5.0.post21
pip install gradio

echo *** %time% *** Downloading models
pip install hf_xet
hf download --local-dir ./ckpt HeartMuLa/HeartMuLaGen
hf download --local-dir ./ckpt/HeartMuLa-oss-3B HeartMuLa/HeartMuLa-oss-3B
hf download --local-dir ./ckpt/HeartCodec-oss HeartMuLa/HeartCodec-oss

call venv\scripts\deactivate.bat
cd ..
echo *** %time% *** Finished HeartMula install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause
