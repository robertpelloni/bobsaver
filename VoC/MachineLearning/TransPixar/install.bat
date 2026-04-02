@echo off



cd
echo *** Deleting TransPixar directory if it exists
if exist TransPixar\. rd /S /Q TransPixar

echo *** Cloning TransPixar repository
git clone https://github.com/wileewang/TransPixar
cd TransPixar

echo *** Creating venv
python -m venv venv
call venv\scripts\activate.bat

echo *** Upgrading pip
python -m pip install --upgrade pip==24.3.1

echo *** Installing requirements.txt
pip install -r requirements.txt

echo *** Installing GPU torch
pip uninstall -y torch
pip uninstall -y torch
rem pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.3.1+cu121 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.7.0+cu128 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128

echo *** Patching typing_extensions
pip uninstall -y typing_extensions
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts typing_extensions==4.11.0

echo *** Patching pydantic
pip uninstall -y pydantic
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts pydantic==2.10.6

call venv\scripts\deactivate.bat
cd..

echo *** Finished TransPixar install
echo.
echo *** Scroll up and check for errors.  Do not assume it worked.
pause

