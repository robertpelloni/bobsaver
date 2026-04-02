@echo off



if exist LLaDA\. rd /S /Q LLaDA

echo *** %time% *** Cloning ACE-Step repository
git clone https://github.com/ML-GSAI/LLaDA
cd LLaDA

echo *** Creating venv
python -m venv venv
call venv\scripts\activate.bat

echo *** %time% *** Installing requirements
python -m pip install --upgrade pip==24.3.1
pip install wheel
pip install setuptools
rem pip install -r requirements.txt
pip install transformers==4.38.2 
pip install gradio

pip uninstall -y torch
pip uninstall -y torch
pip install torch==2.7.0+cu128 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128

cd ..
echo *** %time% VoC *** Finished LLaDA install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause
