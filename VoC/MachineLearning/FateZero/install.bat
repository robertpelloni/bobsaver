@echo off
cls
D:
cd "D:\code\Delphi\Chaos\Examples\MachineLearning\FateZero"

echo *** VoC - Deleting FateZero directory if it exists
if exist FateZero. rd /S /Q FateZero

echo *** VoC - Deleting .venv directory if it exists
if exist .venv\. rd /S /Q .venv
echo *** VoC - setting up virtual environment
python -m venv .venv
echo *** VoC - activating virtual environment
call .venv\scripts\activate.bat

echo *** VoC - git clone
git clone https://huggingface.co/spaces/chenyangqi/FateZero

echo *** VoC - upgrading pip
python.exe -m pip install --upgrade pip

echo *** VoC - installing requirements
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts wheel==0.38.4
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts accelerate==0.15.0
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts bitsandbytes==0.35.4
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts decord==0.6.0
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts diffusers[torch]==0.11.1
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts einops==0.6.0
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts ftfy==6.1.1
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts gradio==3.23.0
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts huggingface-hub==0.13.2
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts imageio==2.25.0
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts imageio-ffmpeg==0.4.8
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts omegaconf==2.3.0
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts Pillow==9.4.0
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts python-slugify==7.0.0
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts tensorboard==2.11.2
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts transformers==4.26.0
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts xformers==0.0.16
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts modelcards==0.1.6
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts click==8.1.3
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts opencv-python==4.7.0.72
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts imageio[ffmpeg]==2.31.1

echo *** VoC - installing GPU torch
pip uninstall -y torch
pip uninstall -y torch
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==1.13.1+cu116 torchvision==0.14.1+cu116 torchaudio==0.13.1+cu116 --extra-index-url https://download.pytorch.org/whl/cu116

echo *** VoC - patching typing_extensions
pip uninstall -y typing_extensions
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts typing_extensions==4.11.0

echo *** VoC - git cloning huggingface repoositories
echo *** NOTE: This can take a while.  Do not assume it has hung.  Check Task Manager for network activity as the downloads happen.
cd FateZero\FateZero\ckpt
git clone https://huggingface.co/CompVis/stable-diffusion-v1-4
rem git clone https://huggingface.co/runwayml/stable-diffusion-v1-5
git clone https://huggingface.co/stable-diffusion-v1-5/stable-diffusion-v1-5
git clone https://huggingface.co/chenyangqi/jeep_tuned_200
git clone https://huggingface.co/chenyangqi/man_skate_250
git clone https://huggingface.co/chenyangqi/swan_150

echo *** VoC - downloading required data files
cd..
cd..
cd..
curl -L -o FateZero\FateZero\data\attribute.zip https://github.com/ChenyangQiQi/FateZero/releases/download/v1.0.0/attribute.zip -v
curl -L -o FateZero\FateZero\data\negative_reg.zip https://github.com/ChenyangQiQi/FateZero/releases/download/v1.0.0/negative_reg.zip -v
curl -L -o FateZero\FateZero\data\style.zip https://github.com/ChenyangQiQi/FateZero/releases/download/v1.0.0/style.zip -v
curl -L -o FateZero\FateZero\data\shape.zip https://github.com/ChenyangQiQi/FateZero/releases/download/v1.0.0/shape.zip -v

echo *** VoC - unzipping required data files
7z x FateZero\FateZero\data\attribute.zip -oFateZero\FateZero\data\attribute
7z x FateZero\FateZero\data\negative_req.zip -oFateZero\FateZero\data\negative_req
7z x FateZero\FateZero\data\style.zip -oFateZero\FateZero\data\style
7z x FateZero\FateZero\data\shape.zip -oFateZero\FateZero\data\shape

echo.
echo *** VoC - finished FateZero Infinity install

echo.
echo *** Scroll up and check for any error messages.  Do not assume the install worked. ***
pause
