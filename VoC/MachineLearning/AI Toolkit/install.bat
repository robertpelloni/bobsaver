@echo off



echo *** %time% *** Deleting ai-toolkit directory if it exists
if exist ai-toolkit\. rd /S /Q ai-toolkit

echo *** %time% *** Cloning ai-toolkit repository
git clone https://github.com/ostris/ai-toolkit
cd ai-toolkit
git submodule update --init --recursive

copy config\examples\train_lora_flux_24gb.yaml config\train_lora_flux_24gb.yaml

echo *** %time% *** Removing sqlite3 from requirements.txt
type requirements.txt | findstr /v sqlite3 > stripped.txt
del requirements.txt
ren stripped.txt requirements.txt

echo *** %time% *** Creating venv
python -m venv venv

echo *** %time% *** Activating venv
call venv\scripts\activate.bat

echo *** %time% *** Installing requirements
python -m pip install --upgrade pip==24.3.1

echo *** %time% *** Installing requirements
pip install -r requirements.txt

echo *** %time% *** Installing GPU torch
pip uninstall -y torch
pip uninstall -y torch
rem pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.5.1+cu124 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.7.0+cu128 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128

echo *** VoC - patching typing_extensions
pip uninstall -y typing_extensions
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts typing_extensions==4.11.0

call venv\scripts\deactivate.bat
cd ..
echo *** %time% *** Finished ai-toolkit install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause
