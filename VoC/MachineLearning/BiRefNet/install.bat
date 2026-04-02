@echo off



cd BiRefNet

echo *** %time% *** Cloning BiRefNet repository
git clone https://github.com/ZhengPeng7/BiRefNet
copy app.py BiRefNet
cd BiRefNet

echo *** Creating venv
python -m venv venv
call venv\scripts\activate.bat

echo *** %time% *** Installing requirements
python -m pip install --upgrade pip==24.3.1
pip install wheel
pip install setuptools
pip install -r requirements.txt
pip install transformers
pip install gradio

pip uninstall -y torch
pip uninstall -y torch
pip install torch==2.7.0+cu128 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128
rem pip install torch==2.4.0 torchvision==0.19.0 torchaudio==2.4.0 --index-url https://download.pytorch.org/whl/cu124

call venv\scripts\deactivate.bat
cd ..

echo *** %time% *** Finished BiRefNet installation
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause
