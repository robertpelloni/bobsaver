@echo off



echo *** %time% *** Deleting InfiniteTalk directory if it exists
if exist InfiniteTalk\. rd /S /Q InfiniteTalk

echo *** %time% *** Cloning repository
git clone https://github.com/MeiGen-AI/InfiniteTalk
cd InfiniteTalk
copy ..\ffmpeg.exe
copy ..\ffprobe.exe

echo *** %time% *** Creating venv
python -m venv venv

echo *** %time% *** Activating venv
call venv\scripts\activate.bat

echo *** %time% *** Removing moviepy from requirements.txt
type requirements.txt | findstr /v moviepy > stripped.txt
del requirements.txt
ren stripped.txt requirements.txt

echo *** %time% *** Removing numpy from requirements.txt
type requirements.txt | findstr /v numpy > stripped.txt
del requirements.txt
ren stripped.txt requirements.txt

echo *** %time% *** Installing requirements
python -m pip install --upgrade pip
pip install misaki[en]
pip install ninja 
pip install psutil 
pip install packaging 
pip install https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/flash_attn-2.7.4.post1-cp310-cp310-win_amd64.whl
pip install moviepy==1.0.3
pip install soundfile
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts xformers==0.0.30
pip install "triton-windows<3.4"
pip install librosa

echo *** %time% *** Installing requirements.txt
pip install -r requirements.txt

echo *** %time% *** Installing GPU torch
pip uninstall -y torch
pip uninstall -y torch
pip uninstall -y torch
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.7.0+cu128 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128

pip uninstall -y transformers
pip install transformers==4.52

echo *** %time% *** Downloading models
pip install -U "huggingface_hub[cli]"
pip install hf_xet
echo *** %time% *** Downloading Wan-AI/Wan2.1-I2V-14B-480P
hf download Wan-AI/Wan2.1-I2V-14B-480P --local-dir ./weights/Wan2.1-I2V-14B-480P
echo *** %time% *** Downloading TencentGameMate/chinese-wav2vec2-base
hf download TencentGameMate/chinese-wav2vec2-base --local-dir ./weights/chinese-wav2vec2-base
echo *** %time% *** Downloading TencentGameMate/chinese-wav2vec2-base model.safetensors
hf download TencentGameMate/chinese-wav2vec2-base model.safetensors --revision refs/pr/1 --local-dir ./weights/chinese-wav2vec2-base
echo *** %time% *** Downloading MeiGen-AI/InfiniteTalk
hf download MeiGen-AI/InfiniteTalk --local-dir ./weights/InfiniteTalk

pip uninstall -y networkx
pip uninstall -y networkx
pip uninstall -y networkx
pip install networkx

call venv\scripts\deactivate.bat
cd ..
echo *** %time% *** Finished InfiniteTalk install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause
