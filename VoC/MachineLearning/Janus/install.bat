@echo off



cd
echo *** Deleting Janus directory if it exists
if exist Janus\. rd /S /Q Janus

echo *** Cloning Janus repository
git clone https://github.com/deepseek-ai/Janus
cd Janus

echo *** Creating venv
python -m venv venv
call venv\scripts\activate.bat

echo *** Upgrading pip
python -m pip install --upgrade pip==24.3.1

echo *** Installing requirements
pip install -r requirements.txt
pip install diffusers[torch]
pip install -e .[gradio]

echo *** Installing GPU Torch
pip uninstall -y torch
pip uninstall -y torch
rem pip install torch==2.5.1+cu124 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124
pip install torch==2.7.0+cu128 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128

call venv\scripts\deactivate.bat
cd..

echo *** Finished Janus install
echo.
echo *** Scroll up and check for errors.  Do not assume it worked.
pause
