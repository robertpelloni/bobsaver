@echo off



echo *** %time% VoC *** Deleting AniPortrait directory if it exists
if exist AniPortrait\. rd /S /Q AniPortrait

echo *** %time% VoC *** Cloning AniPortrait repository
git clone https://github.com/Zejun-Yang/AniPortrait
copy ffmpeg.exe AniPortrait\ffmpeg.exe
copy ffprobe.exe AniPortrait\ffprobe.exe
cd AniPortrait

echo *** %time% VoC *** Creating venv
python -m venv venv

echo *** %time% VoC *** Activating venv
call venv\scripts\activate.bat

echo *** %time% VoC *** Installing requirments
python -m pip install -U pip
python -m pip install pip==24.0
pip install -r requirements.txt

echo *** VoC - patching xformers
pip uninstall -y xformers
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts xformers==0.0.25 --index-url https://download.pytorch.org/whl/cu118

echo *** VoC - installing GPU torch
pip uninstall -y torch
pip uninstall -y torch
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.2.1+cu118 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118

echo *** VoC - patching typing_extensions
pip uninstall -y typing_extensions
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts typing_extensions==4.11.0

echo *** %time% VoC *** Downloading models
rd pretrained_model /s/q
git clone https://huggingface.co/ZJYang/AniPortrait
ren AniPortrait pretrained_model
cd pretrained_model
rem git clone https://huggingface.co/runwayml/stable-diffusion-v1-5
git clone https://huggingface.co/stable-diffusion-v1-5/stable-diffusion-v1-5
git clone https://huggingface.co/stabilityai/sd-vae-ft-mse
git clone https://huggingface.co/facebook/wav2vec2-base-960h
md image_encoder
curl -L -o "image_encoder\config.json" "https://huggingface.co/lambdalabs/sd-image-variations-diffusers/resolve/main/image_encoder/config.json" -v
curl -L -o "image_encoder\pytorch_model.bin" "https://huggingface.co/lambdalabs/sd-image-variations-diffusers/resolve/main/image_encoder/pytorch_model.bin" -v

cd ..
call venv\scripts\deactivate.bat
cd ..
echo *** %time% VoC *** Finished AniPortrait install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause
