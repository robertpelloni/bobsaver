@echo off



if exist ACE-Step-1.5\. rd /S /Q ACE-Step-1.5

echo *** %time% *** Cloning ACE-Step repository
git clone https://github.com/ace-step/ACE-Step-1.5
cd ACE-Step-1.5

echo *** Creating venv
python -m venv venv
call venv\scripts\activate.bat

echo *** %time% *** Installing requirements
python -m pip install --upgrade pip
pip install wheel
pip install setuptools
pip install -r requirements.txt
pip install hf_xet

pip uninstall -y torch
pip uninstall -y torch
pip install torch==2.7.0+cu128 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128

cd ..
echo *** %time% VoC *** Finished ACE-Step-1.5 install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause
