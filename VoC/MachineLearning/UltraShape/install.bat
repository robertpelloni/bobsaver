@echo off



echo *** %time% *** Deleting UltraShape directory if it exists
if exist UltraShape\. rd /S /Q UltraShape

echo *** %time% *** Cloning repository
git clone https://github.com/PKU-YuanGroup/UltraShape-1.0.git
move UltraShape-1.0 UltraShape
cd UltraShape

echo *** %time% *** Creating venv
python -m venv venv

echo *** %time% *** Activating venv
call venv\scripts\activate.bat

echo *** %time% *** Upgrading pip
python.exe -m pip install --upgrade pip
pip install wheel==0.45.1
pip install setuptools==65.5.0
pip install ninja==1.11.1.4

echo *** %time% *** Installing GPU torch
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.7.0+cu128 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128

echo *** Removing deepspeed from requirements.txt
type requirements.txt | findstr /v deepspeed > stripped.txt
del requirements.txt
ren stripped.txt requirements.txt

echo *** Removing flash-attn from requirements.txt
type requirements.txt | findstr /v flash > stripped.txt
del requirements.txt
ren stripped.txt requirements.txt

echo *** %time% *** Installing requirements
pip install --no-build-isolation -r requirements.txt
pip install https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/deepspeed-0.16.3-cp310-cp310-win_amd64.whl
pip install https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/flash_attn-2.7.4.post1-cp310-cp310-win_amd64.whl
pip install gradio
pip install hf_xet

echo *** %time% *** Installing GPU torch
pip uninstall -y torch
pip uninstall -y torch
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.7.0+cu128 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128

echo *** %time% *** Installing cubvh
pip install "https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/cubvh-0.1.2+cu128.torch271-cp310-cp310-win_amd64.whl" --no-build-isolation

rem For Training & Sampling (Optional)
rem pip install --no-build-isolation "git+https://github.com/facebookresearch/pytorch3d.git@stable"
rem pip install https://data.pyg.org/whl/torch-2.5.0%2Bcu121/torch_cluster-1.6.3%2Bpt25cu121-cp310-cp310-linux_x86_64.whl

echo *** %time% *** Downloading models
if not exist checkpoints\. md checkpoints
curl -L -o checkpoints\ultrashape_v1.pt https://huggingface.co/infinith/UltraShape/resolve/main/ultrashape_v1.pt

call venv\scripts\deactivate.bat
cd ..
echo *** %time% *** Finished UltraShape install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause
