@echo off



cd
echo *** Deleting MeshAnything directory if it exists
if exist MeshAnything\. rd /S /Q MeshAnything

echo *** Cloning MeshAnything repository
git clone https://github.com/buaacyw/MeshAnything
cd MeshAnything

echo *** Creating venv
python -m venv venv
call venv\scripts\activate.bat

echo *** Installing MeshAnything requirements
python -m pip install --upgrade pip==24.3.1
pip install wheel
pip install -r requirements.txt

echo *** Installing flash-attn
rem pip install flash-attn --no-build-isolation
set CUDA_HOME=%CUDA_PATH%
echo CUDA_PATH = %CUDA_PATH%
echo CUDA_HOME = %CUDA_HOME%
pip install packaging
pip install ninja
pip uninstall -y matplotlib
pip install matplotlib==3.8.0
pip install https://softology.pro/wheels/flash_attn-2.5.9.post1+cu122torch2.3.0cxx11abiFALSE-cp310-cp310-win_amd64.whl

echo *** Installing GPU torch
pip uninstall -y torch
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.3.1+cu121 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121

echo *** VoC - patching typing_extensions
pip uninstall -y typing_extensions
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts typing_extensions==4.11.0

call venv\scripts\deactivate.bat
cd..

echo *** Finished MeshAnything install
echo.
echo *** Scroll up and check for errors.  Do not assume it worked.
pause


