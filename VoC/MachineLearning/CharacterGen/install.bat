@echo off



echo *** %time% VoC *** Deleting CharacterGen directory if it exists
if exist CharacterGen\. rd /S /Q CharacterGen

echo *** %time% VoC *** Cloning ExUI repository
git clone https://github.com/zjp-shadow/CharacterGen
cd CharacterGen

echo *** %time% VoC *** Creating venv
python -m venv venv

echo *** %time% VoC *** Activating venv
call venv\scripts\activate.bat

echo *** %time% VoC *** Installing requirements
python -m pip install --upgrade pip==24.3.1
rem python -m pip install -U pip
rem python -m pip install pip==24.0
pip install wheel
pip install -r requirements.txt

echo *** %time% VoC - patching xformers
pip uninstall -y xformers
rem pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts xformers==0.0.27 --index-url https://download.pytorch.org/whl/cu121
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts xformers==0.0.30

echo *** %time% VoC - installing GPU torch
pip uninstall -y torch
pip uninstall -y torch
rem pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.3.1+cu121 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121
rem pip uninstall -y charset-normalizer
rem pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts charset-normalizer==3.3.2
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.7.0+cu128 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128

echo *** VoC - patching typing_extensions
pip uninstall -y typing_extensions
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts typing_extensions==4.11.0

call venv\scripts\deactivate.bat
cd ..

echo *** %time% VoC *** Finished CharacterGen install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause
