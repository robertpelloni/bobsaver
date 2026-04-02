@echo off



echo *** %time% *** Deleting EasyAnimate directory if it exists
if exist EasyAnimate\. rd /S /Q EasyAnimate

echo *** Cloning EasyAnimate repository
git clone https://github.com/aigc-apps/EasyAnimate
cd EasyAnimate

echo *** Creating venv
python -m venv venv
call venv\scripts\activate.bat

echo *** %time% *** Removing xformers from requirements.txt
type requirements.txt | findstr /v xformers > stripped.txt
del requirements.txt
ren stripped.txt requirements.txt

echo *** %time% *** Removing deepspeed from requirements.txt
type requirements.txt | findstr /v deepspeed > stripped.txt
del requirements.txt
ren stripped.txt requirements.txt

echo *** Installing requirments.txt
python -m pip install --upgrade pip
pip install wheel
pip install setuptools
pip install -r requirements.txt

echo *** Installing other required packages
pip install https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/deepspeed-0.12.7+40342055-py3-none-any.whl
rem pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts xformers==0.0.25 --index-url https://download.pytorch.org/whl/cu118
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts xformers==0.0.30
pip uninstall -y torch
pip uninstall -y torch
rem pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.2.2+cu118 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.7.0+cu128 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts beautifulsoup4==4.12.3
pip uninstall -y typing-extensions
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts typing-extensions==4.11.0
pip install https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/triton-3.0.0-cp310-cp310-win_amd64.whl
pip uninstall -y pydantic
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts pydantic==2.10.6
pip uninstall -y triton
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts triton-windows==3.5.0.post21

echo *** Downloading models
git lfs install
md models
cd models
git clone https://huggingface.co/alibaba-pai/EasyAnimateV5-12b-zh-InP
git clone https://huggingface.co/alibaba-pai/EasyAnimateV5-12b-zh-Control
git clone https://huggingface.co/alibaba-pai/EasyAnimateV5-12b-zh
md Diffusion_Transformer
move EasyAnimateV5-12b-zh Diffusion_Transformer\EasyAnimateV5-12b-zh

cd ..
call venv\scripts\deactivate.bat
cd ..

echo *** Finished EasyAnimate install
echo.
pause


