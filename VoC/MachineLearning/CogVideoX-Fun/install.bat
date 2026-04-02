@echo off



echo *** %time% *** Deleting CogVideoX-Fun directory if it exists
if exist CogVideoX-Fun\. rd /S /Q CogVideoX-Fun

echo *** %time% *** Cloning repository
git clone https://github.com/aigc-apps/CogVideoX-Fun
cd CogVideoX-Fun

echo *** %time% *** Removing deepspeed from requirements.txt
type requirements.txt | findstr /v deepspeed > stripped.txt
del requirements.txt
ren stripped.txt requirements.txt

echo *** %time% *** Creating venv
python -m venv venv

echo *** %time% *** Activating venv
call venv\scripts\activate.bat

echo *** %time% *** Installing requirements
python -m pip install --upgrade pip==24.3.1
pip install wheel
pip install setuptools
pip install torch
pip install -r requirements.txt
pip install https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/deepspeed-0.12.7+40342055-py3-none-any.whl
pip install librosa

echo *** %time% *** Patching xformers
pip uninstall -y xformers
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts xformers==0.0.30

echo *** %time% *** Installing GPU torch
pip uninstall -y torch
pip uninstall -y torch
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.7.0+cu128 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128

echo *** %time% *** Rolling back gradio
pip uninstall -y gradio
pip install gradio==3.48.0

echo *** VoC - patching typing_extensions
pip uninstall -y typing_extensions
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts typing_extensions==4.11.0

echo *** VoC - patching pydantic
pip uninstall -y pydantic
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts pydantic==2.10.6


echo *** %time% *** Downloading models
cd models
md Diffusion_Transformer
cd Diffusion_Transformer
curl -L -o CogVideoX-Fun-2b-InP.tar.gz https://pai-aigc-photog.oss-cn-hangzhou.aliyuncs.com/cogvideox_fun/Diffusion_Transformer/CogVideoX-Fun-2b-InP.tar.gz -v
curl -L -o CogVideoX-Fun-5b-InP.tar.gz https://pai-aigc-photog.oss-cn-hangzhou.aliyuncs.com/cogvideox_fun/Diffusion_Transformer/CogVideoX-Fun-5b-InP.tar.gz -v

echo *** %time% *** Extracting models
..\..\..\7z x CogVideoX-Fun-2b-InP.tar.gz
..\..\..\7z x CogVideoX-Fun-2b-InP.tar
..\..\..\7z x CogVideoX-Fun-5b-InP.tar.gz
..\..\..\7z x CogVideoX-Fun-5b-InP.tar
del CogVideoX-Fun-2b-InP.tar.gz
del CogVideoX-Fun-5b-InP.tar.gz
del CogVideoX-Fun-2b-InP.tar
del CogVideoX-Fun-5b-InP.tar

cd..
cd..
call venv\scripts\deactivate.bat
cd ..
echo *** %time% *** Finished CogVideoX-Fun install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause
