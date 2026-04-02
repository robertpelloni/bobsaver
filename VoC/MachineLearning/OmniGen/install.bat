@echo off



echo *** %time% *** Deleting OmniGen directory if it exists
if exist OmniGen\. rd /S /Q OmniGen

echo *** %time% *** Cloning OmniGen repository
git clone https://github.com/newgenai79/OmniGen
cd OmniGen

rem echo *** %time% *** Removing flash-attn from requirements.txt
rem type requirements.txt | findstr /v flash-attn > stripped.txt
rem del requirements.txt
rem ren stripped.txt requirements.txt

echo *** %time% *** Creating venv
python -m venv venv

echo *** %time% *** Activating venv
call venv\scripts\activate.bat

echo *** %time% *** Installing requirements
python -m pip install --upgrade pip==24.3.1
pip install -r requirements.txt

echo *** VoC - patching typing_extensions
pip uninstall -y typing_extensions
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts typing_extensions==4.11.0
pip install hf_xet

echo *** VoC - patching gradio
pip uninstall -y gradio
pip install gradio==5.33.0

echo *** %time% *** Installing GPU torch
pip uninstall -y torch
pip uninstall -y torch
pip install torch==2.7.0+cu128 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128

call venv\scripts\deactivate.bat
cd ..
echo *** %time% *** Finished OmniGen install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause
