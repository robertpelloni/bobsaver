@echo off



cd
echo *** Deleting stable-point-aware-3d directory if it exists
if exist stable-point-aware-3d\. rd /S /Q stable-point-aware-3d

echo *** Cloning stable-point-aware-3d repository
git clone https://github.com/Stability-AI/stable-point-aware-3d
cd stable-point-aware-3d

echo *** Creating venv
python -m venv venv
call venv\scripts\activate.bat

echo *** Upgrading pip
python -m pip install --upgrade pip==24.3.1

echo *** Installing GPU torch
pip uninstall -y torch
pip uninstall -y torch
rem pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.5.1+cu121 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.7.0+cu128 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128

echo *** Installing requirements.txt
pip install -U setuptools==69.5.1
pip install wheel
pip install -r requirements.txt
pip uninstall -y flet
pip install flet==0.23.1

echo *** Installing requirements-remesh.txt
pip install -r requirements-remesh.txt

echo *** Installing requirements-demo.txt
pip install -r requirements-demo.txt

echo *** Installing GPU torch
pip uninstall -y torch
pip uninstall -y torch
rem pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.5.1+cu121 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.7.0+cu128 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128

echo *** Patching typing_extensions
pip uninstall -y typing_extensions
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts typing_extensions==4.11.0

echo *** Patching pydantic
pip uninstall -y pydantic
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts pydantic==2.10.6

call venv\scripts\deactivate.bat
cd..

echo *** Finished stable-point-aware-3d install
echo.
echo *** Scroll up and check for errors.  Do not assume it worked.
pause

