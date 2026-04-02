@echo off




echo *** %time% VoC *** Deleting sd-diffuser-webui directory if it exists
if exist sd-diffuser-webui\. rd /S /Q sd-diffuser-webui

echo *** %time% VoC *** Cloning sd-diffuser-webui repository
git clone https://github.com/newgenai79/sd-diffuser-webui
cd sd-diffuser-webui

echo *** Creating venv
python -m venv venv
call venv\scripts\activate.bat

echo *** %time% VoC *** Stripping 3.11 from requirements_windows.txt
type requirements_windows.txt | findstr /v 3.11 > stripped.txt
del requirements_windows.txt
ren stripped.txt requirements_windows.txt

echo *** %time% VoC *** Stripping 3.12 from requirements_windows.txt
type requirements_windows.txt | findstr /v 3.12 > stripped.txt
del requirements_windows.txt
ren stripped.txt requirements_windows.txt

echo *** %time% VoC *** Stripping torchaudio from requirements_windows.txt
type requirements_windows.txt | findstr /v torchaudio > stripped.txt
del requirements_windows.txt
ren stripped.txt requirements_windows.txt

echo *** %time% VoC *** Stripping torchvision from requirements_windows.txt
type requirements_windows.txt | findstr /v torchvision > stripped.txt
del requirements_windows.txt
ren stripped.txt requirements_windows.txt

echo *** %time% VoC *** Stripping torch==2.5.1 from requirements_windows.txt
type requirements_windows.txt | findstr /v torch==2.5.1 > stripped.txt
del requirements_windows.txt
ren stripped.txt requirements_windows.txt

echo *** %time% *** Installing requirements
python -m pip install --upgrade pip==24.3.1
pip install -r requirements_windows.txt

echo *** VoC - Installing GPU torch
pip uninstall -y torch
pip uninstall -y torch
pip uninstall -y torch
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.5.1+cu124 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124

cd ..
echo *** %time% VoC *** Finished sd-diffuser-webui install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause
