@echo off



echo *** %time% VoC *** Deleting Face-Adapter directory if it exists
if exist Face-Adapter\. rd /S /Q Face-Adapter

echo *** %time% VoC *** Cloning Face-Adapter repository
git clone https://github.com/FaceAdapter/Face-Adapter
cd Face-Adapter

echo *** %time% VoC *** Creating venv
python -m venv venv

echo *** %time% VoC *** Activating venv
call venv\scripts\activate.bat

echo *** %time% VoC *** Installing requirements
python -m pip install -U pip
python -m pip install pip==24.0

pip install -r requirements.txt

rem echo *** VoC - patching xformers
rem pip uninstall -y xformers
rem pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts xformers==0.0.25 --index-url https://download.pytorch.org/whl/cu118

echo *** VoC - patching packages
pip uninstall -y huggingface-hub
pip install huggingface-hub==0.23.0
pip install fastai

echo *** VoC - installing GPU torch
pip uninstall -y torch
pip uninstall -y torch
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.0.0+cu118 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
pip uninstall -y charset-normalizer
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts charset-normalizer==3.3.2

echo *** VoC - patching typing_extensions
pip uninstall -y typing_extensions
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts typing_extensions==4.11.0

echo *** VoC - patching pydantic
pip uninstall -y pydantic
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts pydantic==2.10.6

echo *** VoC - patching numpy
pip uninstall -y numpy
pip uninstall -y numpy
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts numpy==1.26.4

call venv\scripts\deactivate.bat
cd ..
echo *** %time% VoC *** Finished Face-Adapter install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause
