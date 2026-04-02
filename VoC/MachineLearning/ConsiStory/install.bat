@echo off



echo *** %time% *** Deleting consistory directory if it exists
if exist consistory\. rd /S /Q consistory

echo *** %time% *** Cloning consistory repository
git clone https://github.com/NVlabs/consistory
copy requirements.txt consistory\requirements.txt
cd consistory

echo *** %time% *** Creating venv
python -m venv venv

echo *** %time% *** Activating venv
call venv\scripts\activate.bat

rem echo *** %time% *** Removing deepspeed from requirements.txt
rem type requirements.txt | findstr /v deepspeed > stripped.txt
rem del requirements.txt
rem ren stripped.txt requirements.txt

echo *** %time% *** Installing requirements
python -m pip install --upgrade pip==24.3.1
pip install -r requirements.txt

echo *** %time% *** Installing xformers
pip uninstall -y xformers
rem pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts xformers==0.0.27
rem pip install https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/xformers-0.0.30+836cd905.d20250327-cp310-cp310-win_amd64.whl
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts xformers==0.0.30

echo *** %time% *** Installing GPU torch
pip uninstall -y torch
pip uninstall -y torch
rem pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.3.1+cu121 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121
pip install torch==2.7.0+cu128 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128

rem echo *** %time% *** Patching huggingface-hub
rem pip uninstall -y huggingface-hub
rem pip install huggingface-hub==0.25.0

echo *** VoC - patching typing_extensions
pip uninstall -y typing_extensions
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts typing_extensions==4.11.0

echo *** VoC - patching numpy
pip uninstall -y numpy
pip uninstall -y numpy
pip uninstall -y numpy
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts numpy==1.26.4

call venv\scripts\deactivate.bat
cd ..
echo *** %time% *** Finished ConsiStory install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause
