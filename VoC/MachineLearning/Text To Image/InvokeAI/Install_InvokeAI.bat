@echo off

D:


echo *** VoC - Deleting InvokeAI directory if it exists
if exist InvokeAI\. rd /S /Q InvokeAI
echo *** VoC - installing InvokeAI

echo *** VoC - activating venv
call InvokeAI\.venv\scripts\activate.bat
echo *** VoC - updating pip
python.exe -m pip install --upgrade pip

echo *** %time% *** Patching xformers
pip uninstall -y xformers
rem pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts xformers==0.0.27.post2 --index-url https://download.pytorch.org/whl/cu121
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts xformers==0.0.30

echo *** %time% *** Installing GPU torch
pip uninstall -y torch
pip uninstall -y torch
rem pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.4.0+cu121 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121
pip install torch==2.7.0+cu128 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128

rem pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124
rem echo *** VoC - installing other requirements GPU torch needs
rem pip uninstall -y typing_extensions
rem pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts typing_extensions==4.8.0
rem pip uninstall -y charset-normalizer
rem pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts charset-normalizer==3.3.2

echo *** VoC - finished InvokeAI install
pause
