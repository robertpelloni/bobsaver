@echo off

D:
cd "D:\code\delphi\Chaos\Examples\MachineLearning\OpenVINO Notebooks\"
if exist openvino-notebooks\. rd /S /Q openvino-notebooks

echo *** VoC - Deleting venv directory if it exists
if exist venv\. rd /S /Q venv

echo *** VoC - Creating venv
python -m venv venv

echo *** VoC - Activating venv
call venv\scripts\activate.bat

echo *** VoC - Cloning OpenVINO Notebooks repository
git clone --depth=1 https://github.com/openvinotoolkit/openvino_notebooks.git
cd openvino_notebooks

echo *** VoC - Installing requirements
python -m pip install -U pip
python -m pip install pip==24.0
pip install wheel setuptools
pip install -r requirements.txt

cd ..
echo *** VoC - finished OpenVINO Notebooks install
echo.
echo *** Scroll up and check for any error messages.  Do not assume the install worked. ***
pause




