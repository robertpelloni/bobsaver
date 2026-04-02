@echo off
cls



if not exist Rerender_A_Video\models\. goto skip1
echo *** VoC - Backing up existing Rerender_A_Video\models
move Rerender_A_Video\models models_backup

:skip1
echo *** VoC - Deleting Rerender_A_Video directory if it exists
if exist Rerender_A_Video. rd /S /Q Rerender_A_Video

echo *** VoC - Deleting .venv directory if it exists
if exist .venv\. rd /S /Q .venv
echo *** VoC - setting up virtual environment
python -m venv .venv
echo *** VoC - activating virtual environment
call .venv\scripts\activate.bat

echo *** VoC - git clone Render_A_Video
git clone https://github.com/williamyang1991/Rerender_A_Video
cd Rerender_A_Video
cd deps
echo *** VoC - git clone ControlNet
git clone https://github.com/lllyasviel/ControlNet
echo *** VoC - git clone ebsynth
git clone https://github.com/SingleZombie/ebsynth
echo *** VoC - git clone gmflow
git clone https://github.com/haofeixu/gmflow
cd..

echo *** VoC - upgrading pip
python.exe -m pip install --upgrade pip

echo *** VoC - installing requirements
pip install --no-warn-conflicts wheel==0.38.4
pip install --no-warn-conflicts addict==2.4.0
pip install --no-warn-conflicts albumentations==1.3.0
pip install --no-warn-conflicts basicsr==1.4.2
pip install --no-warn-conflicts blendmodes==2023
pip install --no-warn-conflicts einops==0.3.0
pip install --no-warn-conflicts gradio==3.44.3
pip install --no-warn-conflicts imageio==2.9.0
pip install --no-warn-conflicts imageio-ffmpeg==0.4.9
pip install --no-warn-conflicts kornia==0.6
pip install --no-warn-conflicts numba
pip install --no-warn-conflicts omegaconf==2.1.1
pip install --no-warn-conflicts open_clip_torch==2.0.2
pip install --no-warn-conflicts opencv-python==4.8.0.76
pip install --no-warn-conflicts prettytable==3.6.0
pip install --no-warn-conflicts pytorch-lightning==1.5.0
pip install --no-warn-conflicts safetensors==0.2.7
pip install --no-warn-conflicts timm==0.6.12
pip install --no-warn-conflicts torchmetrics==0.6.0
pip install --no-warn-conflicts transformers==4.19.2
pip install --no-warn-conflicts xformers==0.0.30
pip install --no-warn-conflicts yapf==0.32.0
pip install --no-warn-conflicts chardet==5.2.0

echo *** VoC - installing GPU torch
pip uninstall -y torch
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.7.0+cu128 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128

echo *** VoC - fixing typing_extensions
pip uninstall -y typing_extensions
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts typing_extensions==4.11.0

echo *** VoC - fixing pydantic
pip uninstall -y pydantic
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts pydantic==2.10.6

if not exist ..\models_backup\. goto skip2
if exist models\. rd /S /Q models
echo *** VoC - Restoring models
move ..\models_backup models

:skip2

echo *** VoC - Downloading models
if not exist models\. md models
cd models
curl -L -o "gmflow_sintel-0c07dcb3.pth" "https://huggingface.co/PKUWilliamYang/Rerender/resolve/main/models/gmflow_sintel-0c07dcb3.pth" -v
curl -L -o "control_sd15_canny.pth" "https://huggingface.co/lllyasviel/ControlNet/resolve/main/models/control_sd15_canny.pth" -v
curl -L -o "control_sd15_hed.pth" "https://huggingface.co/lllyasviel/ControlNet/resolve/main/models/control_sd15_hed.pth" -v
curl -L -o "vae-ft-mse-840000-ema-pruned.ckpt" "https://huggingface.co/stabilityai/sd-vae-ft-mse-original/resolve/main/vae-ft-mse-840000-ema-pruned.ckpt" -v
curl -L -o "realisticVisionV20_v20.safetensors" "https://huggingface.co/ckpt/realistic-vision-v20/resolve/main/realisticVisionV20_v20.safetensors" -v
curl -L -o "revAnimated_v11.safetensors" "https://huggingface.co/ckpt/rev-animated/resolve/main/revAnimated_v11.safetensors" -v
cd..

echo *** Running install to compile Ebsynth
python install.py

echo *** VoC - Finished Rerender A Video install

echo.
echo *** Scroll up and check for any error messages.  Do not assume the install worked. ***
pause
