@echo off



echo *** %time% *** Deleting DreamCube directory if it exists
if exist DreamCube\. rd /S /Q DreamCube

echo *** %time% *** Cloning repository
git clone https://github.com/yukun-huang/DreamCube
cd DreamCube

echo *** %time% *** Removing pytorch3d from requirements.txt
type requirements.txt | findstr /v pytorch3d > stripped.txt
del requirements.txt
ren stripped.txt requirements.txt

echo *** %time% *** Creating venv
python -m venv venv

echo *** %time% *** Activating venv
call venv\scripts\activate.bat

echo *** %time% *** Upgrading pip
python -m pip install --upgrade pip
pip install wheel==0.45.1
pip install setuptools==65.5.0
pip install ninja==1.11.1.4

echo *** %time% *** Installing requirements
pip install https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/pytorch3d-0.7.8-cp310-cp310-win_amd64.whl
pip install accelerate
pip install -r requirements.txt

echo *** %time% *** Installing GPU torch
pip uninstall -y torch
pip uninstall -y torch
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.7.0+cu128 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128

echo *** %time% *** Patching pydantic
pip uninstall -y pydantic
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts pydantic==2.10.6

call venv\scripts\deactivate.bat
cd ..
echo *** %time% *** Finished DreamCube install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause
