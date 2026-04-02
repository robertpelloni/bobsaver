@echo off



if exist SkyReels-V2\. rd /S /Q SkyReels-V2

echo *** %time% *** Cloning SkyReels-A2 repository
git clone https://github.com/SkyworkAI/SkyReels-V2
cd SkyReels-V2

echo *** Creating venv
python -m venv venv
call venv\scripts\activate.bat

echo *** %time% *** Stripping flash_attn from requirements.txt
type requirements.txt | findstr /v flash_attn > stripped.txt
del requirements.txt
ren stripped.txt requirements.txt

echo *** %time% *** Installing requirements
python -m pip install --upgrade pip==24.3.1
pip install wheel
pip install setuptools
pip install packaging
pip install -r requirements.txt

pip install decord
pip install moviepy==1.0.3

pip install https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/flash_attn-2.7.4.post1-cp310-cp310-win_amd64.whl
pip uninstall -y torch
pip uninstall -y torch
rem pip install --pre torch==2.7.0.dev20250311 torchvision torchaudio --index-url https://download.pytorch.org/whl/nightly/cu128
pip install torch==2.7.0+cu128 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128
pip install -U "triton-windows<3.4"

echo *** %time% *** Downloading models
pip install -U "huggingface_hub[cli]"
pip install hf_xet
hf download Skywork/SkyReels-V2-DF-1.3B-540P --local-dir ./Skywork/SkyReels-V2-DF-1.3B-540P

cd ..
echo *** %time% VoC *** Finished SkyReels-V2 install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause
