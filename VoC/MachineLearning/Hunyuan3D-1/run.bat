@echo off
cd Hunyuan3D-1
set CUDA_HOME=%CUDA_PATH%
echo CUDA_HOME set to %CUDA_HOME%
set FORCE_CUDA=1
call venv\scripts\activate.bat
python app.py
call venv\scripts\deactivate.bat
cd..
