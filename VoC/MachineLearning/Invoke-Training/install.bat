@echo off



echo *** %time% VoC *** Deleting invoke-training directory if it exists
if exist invoke-training\. rd /S /Q invoke-training

echo *** %time% VoC *** Cloning invoke-training repository
git clone https://github.com/invoke-ai/invoke-training.git
cd invoke-training

echo *** %time% VoC *** Creating venv
python -m venv venv

echo *** %time% VoC *** Activating venv
call venv\scripts\activate.bat

echo *** %time% VoC *** Installing requirments
python -m pip install --upgrade pip==24.3.1
pip install ".[test]" --extra-index-url https://download.pytorch.org/whl/cu121

echo *** VoC - patching typing_extensions
pip uninstall -y typing_extensions
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts typing_extensions==4.11.0

rem echo *** VoC - patching xformers
rem pip uninstall -y xformers
rem pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts xformers==0.0.25 --index-url https://download.pytorch.org/whl/cu118

rem echo *** VoC - installing GPU torch
rem pip uninstall -y torch
rem pip uninstall -y torch
rem pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.2.1+cu118 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118

rem echo *** %time% VoC *** Downloading models
rem rd checkpoints /s/q
rem md checkpoints
rem git lfs install
rem git clone https://huggingface.co/auffusion/auffusion-full-no-adapter checkpoints/auffusion
rem git clone https://huggingface.co/ymzhang319/FoleyCrafter checkpoints/

call venv\scripts\deactivate.bat
cd ..
echo *** %time% VoC *** Finished invoke-training install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause
