@echo off



cd
echo *** Deleting MeshAnythingV2 directory if it exists
if exist MeshAnythingV2\. rd /S /Q MeshAnythingV2

echo *** Cloning MeshAnything V2 repository
git clone https://github.com/buaacyw/MeshAnythingV2
cd MeshAnythingV2

echo *** Creating venv
python -m venv venv
call venv\scripts\activate.bat

echo *** Installing MeshAnything V2 requirements
python -m pip install --upgrade pip==24.3.1
pip install wheel
pip install -r requirements.txt

rem echo *** Installing flash-attn
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

echo *** Finished MeshAnything V2 install
echo.
echo *** Scroll up and check for errors.  Do not assume it worked.
pause


