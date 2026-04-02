@echo off



echo *** %time% VoC *** Deleting RC-stable-audio-tools directory if it exists
if exist RC-stable-audio-tools\. rd /S /Q RC-stable-audio-tools

echo *** %time% VoC *** Cloning RC-stable-audio-tools repository
git clone https://github.com/RoyalCities/RC-stable-audio-tools
cd RC-stable-audio-tools

echo *** %time% VoC *** Creating venv
python -m venv venv

echo *** %time% VoC *** Activating venv
call venv\scripts\activate.bat

echo *** %time% VoC *** Installing requirements
python -m pip install --upgrade pip==24.3.1
rem python -m pip install -U pip
rem python -m pip install pip==24.0
pip install wheel
pip install setuptools==49.1.2
pip install stable-audio-tools
pip install .

echo *** %time% VoC - patching xformers
pip uninstall -y xformers
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts xformers==0.0.27 --index-url https://download.pytorch.org/whl/cu118

echo *** %time% VoC - installing GPU torch
pip uninstall -y torch
pip uninstall -y torch
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.3.1+cu118 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
pip uninstall -y charset-normalizer
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts charset-normalizer==3.3.2
pip uninstall -y numpy
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts numpy==1.23.5

echo *** VoC - patching typing_extensions
pip uninstall -y typing_extensions
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts typing_extensions==4.11.0

echo *** VoC - patching numpy
pip uninstall -y numpy
pip uninstall -y numpy
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts numpy==1.26.4

echo *** Downloading models
md ckpt
curl -L -o  "ckpt\ckpt.rar" "https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/SAO.rar" -v

echo *** Extracting models
cd ckpt
..\..\7z x ckpt.rar
del ckpt.rar
cd..

call venv\scripts\deactivate.bat
cd ..

echo *** %time% VoC *** Finished RC-stable-audio-tools install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause
