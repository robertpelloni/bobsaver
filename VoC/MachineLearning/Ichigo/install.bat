@echo off



echo *** Deleting llama3-s directory if it exists
if exist llama3-s\. rd /S /Q llama3-s

echo *** Cloning llama3-s repository
git clone --recurse-submodules https://github.com/homebrewltd/llama3-s.git
cd llama3-s

echo *** Creating venv
python -m venv venv
call venv\scripts\activate.bat

echo *** Installing requirments.txt
python -m pip install --upgrade pip==24.3.1
pip install --no-cache-dir -r demo\requirements.txt

rem echo *** Installing other required packages
rem pip install gradio
rem pip install transformers

echo *** Installing xformers
pip uninstall -y xformers
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts xformers==0.0.30

echo *** Installing GPU torch
pip uninstall -y torch
pip uninstall -y torch
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.7.0+cu128 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128

echo *** VoC - patching typing_extensions
pip uninstall -y typing_extensions
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts typing_extensions==4.11.0

call venv\scripts\deactivate.bat

echo *** Finished llama3-s install
echo.
