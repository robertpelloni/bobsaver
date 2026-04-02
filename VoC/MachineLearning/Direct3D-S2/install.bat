@echo off



cd
echo *** %time% *** Deleting Direct3D-S2 directory if it exists
if exist Direct3D-S2\. rd /S /Q Direct3D-S2

echo *** %time% *** Cloning Direct3D-S2 repository
git clone https://github.com/DreamTechAI/Direct3D-S2
rem patch code bug in udf_kernel.cu
copy udf_kernel.cu Direct3D-S2\third_party\voxelize\src\udf_kernel.cu
rem patch out triton from setup.py
copy setup.py Direct3D-S2\setup.py
cd Direct3D-S2

echo *** %time% *** Creating venv
python -m venv venv
call venv\scripts\activate.bat

echo *** %time% *** Upgrading pip
python -m pip install -U pip
python -m pip install pip==24.0
pip install wheel==0.45.1
pip install setuptools==65.5.0
pip install ninja==1.11.1.4

echo *** %time% *** Removing triton from requirements.txt
type requirements.txt | findstr /v triton > stripped.txt
del requirements.txt
ren stripped.txt requirements.txt

echo *** %time% *** Removing flash-attn from requirements.txt
type requirements.txt | findstr /v flash-attn > stripped.txt
del requirements.txt
ren stripped.txt requirements.txt

echo *** %time% *** Removing torchsparse from requirements.txt
type requirements.txt | findstr /v torchsparse > stripped.txt
del requirements.txt
ren stripped.txt requirements.txt

echo *** %time% *** Removing voxelize from requirements.txt
type requirements.txt | findstr /v voxelize > stripped.txt
del requirements.txt
ren stripped.txt requirements.txt

echo *** %time% *** Installing torch
pip install torch==2.7.0+cu128 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128

echo *** %time% *** Installing torchsparse
pip install https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/torchsparse-2.1.0-cp310-cp310-win_amd64.whl

echo *** %time% *** Installing requirements.txt
pip install -r requirements.txt
pip install https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/udf_ext-0.0.0-cp310-cp310-win_amd64.whl?download=true

echo *** %time% *** Installing .
pip install .

echo *** %time% *** Installing flash-attn
pip install https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/flash_attn-2.7.4.post1-cp310-cp310-win_amd64.whl

echo *** Installing other requirements
pip install trimesh==4.6.10
pip install gradio==5.32.0
pip install kornia==0.8.1
pip install timm==1.0.15
pi pinstall hf_xet

echo *** %time% *** Installing GPU Torch
pip uninstall -y torch
pip uninstall -y torch
pip uninstall -y torch
pip install torch==2.7.0+cu128 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128

pip install triton-windows

call venv\scripts\deactivate.bat
cd..

echo *** %time% *** Finished Direct3D-S2 install
echo.
echo *** %time% *** Scroll up and check for errors.  Do not assume it worked.
pause
