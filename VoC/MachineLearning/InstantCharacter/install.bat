@echo off



if exist InstantCharacter\. rd /S /Q InstantCharacter

echo *** %time% *** Cloning InstantCharacter repository
git clone https://github.com/Tencent/InstantCharacter
cd InstantCharacter

echo *** Creating venv
python -m venv venv
call venv\scripts\activate.bat

echo *** %time% *** Installing requirements
python -m pip install --upgrade pip
pip install wheel==0.45.1
pip install setuptools==65.5.0

rem dev does not provide a requirements.txt yet
rem pip install -r requirements.txt

pip install transformers
pip install diffusers
pip install timm
pip install accelerate
pip install protobuf
pip install sentencepiece
pip install kornia

rem pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts xformers==0.0.30
rem pip install https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/sageattention-2.1.1+cu128torch2.7.0-cp310-cp310-win_amd64.whl
rem pip install https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/flash_attn-2.7.4.post1-cp310-cp310-win_amd64.whl

rem pip install gradio==5.25.2
pip install triton-windows

pip uninstall -y pydantic
pip install pydantic==2.10.6

rem pip install gradio==4.44.1
pip install einops==0.8.1

pip uninstall -y torch
pip uninstall -y torch
pip uninstall -y torch
pip install torch==2.7.0+cu128 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128

echo *** %time% *** Downloading models
huggingface-cli download --resume-download Tencent/InstantCharacter --local-dir checkpoints --local-dir-use-symlinks False

echo *** %time% *** Downloading LoRAs
huggingface-cli download --resume-download InstantX/FLUX.1-dev-LoRA-Ghibli  --local-dir checkpoints/style_lora/ --local-dir-use-symlinks False
huggingface-cli download --resume-download InstantX/FLUX.1-dev-LoRA-Makoto-Shinkai  --local-dir checkpoints/style_lora/ --local-dir-use-symlinks False

cd ..
echo *** %time% VoC *** Finished InstantCharacter install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause
