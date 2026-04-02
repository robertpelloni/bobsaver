@echo off



if exist DiffRhythm\. rd /S /Q DiffRhythm

echo *** %time% VoC *** Cloning DiffRhythm repository
git clone https://github.com/ASLP-lab/DiffRhythm
cd DiffRhythm
copy /Y infer\*.py

echo *** %time% VoC *** Creating venv
python -m venv venv
call venv\scripts\activate.bat

echo *** %time% VoC *** Installing requirements
python -m pip install --upgrade pip==24.3.1
pip install -r requirements.txt
pip install inflect==7.5.0
pip install hf_xet

echo *** %time% VoC *** Installing GPU torch
pip uninstall -y torch
pip uninstall -y torch
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.5.1+cu124 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124

cd ..
echo *** %time% VoC *** Finished DiffRhythm install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause
