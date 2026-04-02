@echo off



echo *** %time% VoC *** Deleting FlowingFrames directory if it exists
if exist FlowingFrames\. rd /S /Q FlowingFrames

echo *** %time% VoC *** Cloning RC-stable-audio-tools repository
git clone https://github.com/motexture/FlowingFrames
cd FlowingFrames

echo *** %time% VoC *** Creating venv
python -m venv venv

echo *** %time% VoC *** Activating venv
call venv\scripts\activate.bat

echo *** %time% VoC *** Installing requirements
python -m pip install --upgrade pip==24.3.1
pip install wheel
pip install -r requirements.txt
pip install accelerate

echo *** %time% VoC - patching xformers
pip uninstall -y xformers
rem pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts xformers==0.0.27 --index-url https://download.pytorch.org/whl/cu118
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts xformers==0.0.30

echo *** %time% VoC - installing GPU torch
pip uninstall -y torch
pip uninstall -y torch
rem pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.3.1+cu118 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.7.0+cu128 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128

pip uninstall -y charset-normalizer
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts charset-normalizer==3.3.2
pip uninstall -y numpy
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts numpy==1.23.5

echo *** VoC - patching typing_extensions
pip uninstall -y typing_extensions
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts typing_extensions==4.11.0

call venv\scripts\deactivate.bat
cd ..

echo *** %time% VoC *** Finished FlowingFrames install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause
