@echo off



cd
echo *** Deleting image-artisan-xl directory if it exists
if exist image-artisan-xl\. rd /S /Q image-artisan-xl

echo *** Cloning image-artisan-xl repository
git clone https://github.com/asomoza/image-artisan-xl
cd image-artisan-xl

echo *** Patching pyproject.toml
rem remove
rem requires-python = ">=3.10"
rem from pyproject.toml so it installs with python 3.10.x VoC uses
rem type pyproject.toml | findstr /v requires-python > pyproject.toml
findstr /V "requires-python" pyproject.toml > pyproject.tmp
del pyproject.toml
ren pyproject.tmp pyproject.toml

echo *** Creating venv
python -m venv venv
call venv\scripts\activate.bat

echo *** Installing requirments
python -m pip install --upgrade pip==24.3.1
pip install .

echo *** Installing GPU Torch
pip uninstall -y torch
pip uninstall -y torch
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.2.1+cu118 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118

echo *** VoC - patching typing_extensions
pip uninstall -y typing_extensions
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts typing_extensions==4.11.0

call venv\scripts\deactivate.bat

cd ..
echo *** Finished image-artisan-xl install
echo.
echo *** Scroll up and check for errors.  Do not assume it worked.
pause


