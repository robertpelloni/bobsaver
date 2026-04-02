@echo off



set CUDA_HOME=%CUDA_PATH%
echo CUDA_HOME set to %CUDA_HOME%

echo *** %time% *** Deleting Hunyuan3D-1 directory if it exists
if exist Hunyuan3D-1\. rd /S /Q Hunyuan3D-1

echo *** %time% *** Cloning DiffSynth-Studio repository
git clone https://github.com/Tencent/Hunyuan3D-1
del Hunyuan3D-1\demos\example_list.txt
copy example_list.txt Hunyuan3D-1\demos\example_list.txt
cd Hunyuan3D-1
rem echo *** %time% *** Rolling back to commit 8d2fd6a971478c488f2e5a12a82f44da88c7093e
rem git checkout 8d2fd6a971478c488f2e5a12a82f44da88c7093e
rem git clean -df

echo *** %time% *** Removing comment from env_install
type env_install.sh | findstr /v # > stripped.txt
del env_install.sh
ren stripped.txt env_install.sh

echo *** %time% *** Removing pytorch3d from env_install
type env_install.sh | findstr /v pytorch3d > stripped.txt
del env_install.sh
ren stripped.txt env_install.sh

echo *** %time% *** Creating venv
python -m venv venv

echo *** %time% *** Activating venv
call venv\scripts\activate.bat

echo *** %time% *** Installing requirements
python -m pip install --upgrade pip==24.3.1
pip install ninja
ren env_install.sh env_install.bat
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/pytorch3d-0.7.8-cp310-cp310-win_amd64.whl
call env_install.bat
pip install gradio==4.44.1
pip install typeguard==4.4.1
pip install onnxruntime==1.20.1

echo *** %time% *** Installing GPU torch
pip uninstall -y torch
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.4.1+cu121 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121

echo *** VoC - patching typing_extensions
pip uninstall -y typing_extensions
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts typing_extensions==4.11.0

rem echo *** VoC - patching diffusers
rem pip uninstall -y diffusers
rem pip install diffusers==0.30.0

echo *** VoC - patching numpy
pip uninstall -y numpy
pip uninstall -y numpy
pip install numpy==1.26.3

echo *** %time% *** Downloading models
if not exist .\weights\. md weights
huggingface-cli download tencent/Hunyuan3D-1 --local-dir ./weights
if not exist .\weights\hunyuanDiT\. md weights\hunyuanDiT
huggingface-cli download Tencent-Hunyuan/HunyuanDiT-v1.1-Diffusers-Distilled --local-dir ./weights/hunyuanDiT

call venv\scripts\deactivate.bat
cd ..
echo *** %time% *** Finished Hunyuan3D-1 install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause
