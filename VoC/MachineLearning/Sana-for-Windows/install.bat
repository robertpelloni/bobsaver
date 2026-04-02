@echo off



if exist Sana-for-Windows\. rd /S /Q Sana-for-Windows

echo *** %time% *** Cloning Sana-for-Windows repository
git clone https://github.com/gjnave/Sana-for-Windows
cd Sana-for-Windows

echo *** Creating venv
python -m venv venv
call venv\scripts\activate.bat

echo *** %time% *** Installing requirements
python -m pip install --upgrade pip==24.3.1
pip install wheel
rem https://github.com/woct0rdho/triton-windows/releases/download/v3.2.0-windows.post10/triton-3.2.0-cp310-cp310-win_amd64.whl
pip install portalocker
pip install -e .
pip install huggingface-hub
pip install huggingface-hub[cli]
pip install gradio
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts xformers==0.0.30

echo *** %time% - Installing GPU torch
rem pip uninstall -y xformers
pip uninstall -y torch
pip uninstall -y torch
rem xformers can be installed with torch
rem pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.6.0+cu124 torchvision torchaudio xformers --index-url https://download.pytorch.org/whl/cu124
pip install torch==2.7.0+cu128 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128
pip install triton-windows
pip install hf_xet
rem echo *** %time% - Downloading models
rem call login-to-sana.bat

cd ..
echo *** %time% VoC *** Finished Sana-for-Windows install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause
