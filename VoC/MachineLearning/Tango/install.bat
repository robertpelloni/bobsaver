@echo off
cls
D:
cd "D:\code\delphi\Chaos\Examples\MachineLearning\Tango"
echo Deleting voc_tango directory if it exists...
if exist voc_tango\. rd voc_tango /s/q
echo Creating voc_tango...
python -m venv voc_tango
echo Activating voc_tango...
call voc_tango\scripts\activate.bat
echo Updating pip
python.exe -m pip install --upgrade pip
echo Installing requirements...
pip install -r requirements.txt
echo Installing diffusers requirements...
cd diffusers
pip install -e .
echo Fixing torch and numpy versions
pip uninstall -y torch
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==1.13.1+cu116 torchvision==0.14.1+cu116 torchaudio==0.13.1+cu116 --extra-index-url https://download.pytorch.org/whl/cu116
pip uninstall -y numpy
pip uninstall -y numpy
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts numpy==1.23.0

echo Patching typing_extensions
pip uninstall -y typing_extensions
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts typing_extensions==4.11.0

echo Install finished

echo.
echo *** Scroll up and check for any error messages.  Do not assume the install worked. ***
pause
