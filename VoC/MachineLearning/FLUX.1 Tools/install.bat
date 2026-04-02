@echo off



echo *** %time% *** Deleting flux directory if it exists
if exist flux\. rd /S /Q flux

echo *** %time% *** Cloning flux repository
git clone https://github.com/black-forest-labs/flux
cd flux

echo *** %time% *** Creating venv
python -m venv venv

echo *** %time% *** Activating venv
call venv\scripts\activate.bat

echo *** %time% *** Installing requirements
python -m pip install --upgrade pip==24.3.1
pip install -e ".[all]"

echo *** %time% *** Installing GPU torch
pip uninstall -y torch
pip uninstall -y torch
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.5.1+cu121 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121

echo *** %time% *** Patching typing_extensions
pip uninstall -y typing_extensions
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts typing_extensions==4.11.0

echo *** %time% *** Patching numpy
pip uninstall -y numpy
pip uninstall -y numpy
pip install numpy==2.1.3

echo *** VoC - patching typing_extensions
pip uninstall -y typing_extensions
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts typing_extensions==4.11.0

call venv\scripts\deactivate.bat
cd ..
echo *** %time% *** Finished FLUX.1 Tools install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause
