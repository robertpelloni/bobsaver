@echo off



cd
echo *** Deleting MMaDA directory if it exists
if exist MMaDA\. rd /S /Q MMaDA

echo *** Cloning MMaDA repository
git clone https://github.com/Gen-Verse/MMaDA
cd MMaDA

echo *** Creating venv
python -m venv venv
call venv\scripts\activate.bat

echo *** Removing deepspeed from requirements.txt
type requirements.txt | findstr /v deepspeed > stripped.txt
del requirements.txt
ren stripped.txt requirements.txt

echo *** Upgrading pip
python -m pip install -U pip
python -m pip install pip==24.0
pip install wheel==0.45.1
pip install setuptools==65.5.0

echo *** Installing requirements
pip install -r requirements.txt
pip install https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/deepspeed-0.16.3-cp310-cp310-win_amd64.whl

echo *** Installing GPU Torch
pip uninstall -y torch
pip uninstall -y torch
pip uninstall -y torch
pip install torch==2.7.0+cu128 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128

call venv\scripts\deactivate.bat
cd..

echo *** Finished MMaDA install
echo.
echo *** Scroll up and check for errors.  Do not assume it worked.
pause

:end
