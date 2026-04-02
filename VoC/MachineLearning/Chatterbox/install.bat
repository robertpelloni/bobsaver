@echo off



cd
echo *** Deleting chatterbox directory if it exists
if exist Chatterbox\. rd /S /Q Chatterbox

echo *** Cloning chatterbox repository
git clone https://github.com/resemble-ai/chatterbox
ren chatterbox Chatterbox
cd Chatterbox

echo *** Creating venv
python -m venv venv
call venv\scripts\activate.bat

echo *** Upgrading pip
python -m pip install -U pip
python -m pip install pip==24.0
pip install wheel==0.45.1
pip install setuptools==65.5.0

echo *** Installing Chatterbox
pip install numpy
pip install chatterbox-tts
rem pip install .

echo *** Installing other requirements
rem pip install gradio==5.31.0
pip install gradio[mcp]==5.44.1
pip install peft==0.15.2

echo *** Installing GPU Torch
pip uninstall -y torch
pip uninstall -y torch
pip uninstall -y torch
pip install torch==2.7.0+cu128 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128

call venv\scripts\deactivate.bat
cd..

echo *** Finished Chatterbox install
echo.
echo *** NOTE: If you get an error about chatterbox dependency above you can safely ignore it.
echo.
echo *** Scroll up and check for errors.  Do not assume it worked.
pause
