@echo off




rem if not exist FIFO-Diffusion\videocrafter_models\base_512_v2\model.ckpt goto skip1
rem echo *** VoC - Backing up existing model
rem move FIFO-Diffusion\videocrafter_models\base_512_v2\model.ckpt model.ckpt

rem :skip1

echo *** Deleting FIFO-Diffusion directory if it exists
if exist FIFO-Diffusion\. rd /S /Q FIFO-Diffusion

echo *** Cloning FIFO-Diffusion repository
git clone https://github.com/jjihwan/FIFO-Diffusion_public

move FIFO-Diffusion_public FIFO-Diffusion
cd FIFO-Diffusion

echo *** %time% *** Removing xformers from requirements.txt
type requirements.txt | findstr /v xformers > stripped.txt
del requirements.txt
ren stripped.txt requirements.txt

echo *** Creating venv
python -m venv venv
call venv\scripts\activate.bat

echo *** Installing requirements
python -m pip install --upgrade pip==24.3.1
pip install -r requirements.txt

echo *** Cloning Open-Sora-Plan repository
git clone https://github.com/PKU-YuanGroup/Open-Sora-Plan

cd Open-Sora-Plan
rem pip install -e .

rem convert pyproject.toml to requirements.txt
pip install toml-to-requirements
toml-to-req --toml-file pyproject.toml

echo *** %time% *** Removing deepspeed from requirements.txt
type requirements.txt | findstr /v deepspeed > stripped.txt
del requirements.txt
ren stripped.txt requirements.txt

echo *** Installing Open-Sora-Plan requirements
pip install -r requirements.txt
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts https://softology.pro/wheels/deepspeed-0.12.6-py3-none-any.whl

cd..

rem echo *** Installing xformers
pip uninstall -y xformers
pip uninstall -y xformers
rem pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts xformers==0.0.25 --index-url https://download.pytorch.org/whl/cu118
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts xformers==0.0.30

echo *** Installing GPU Torch
pip uninstall -y torch
pip uninstall -y torch
pip uninstall -y torch
pip uninstall -y torch
rem pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.2.1+cu118 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
rem pip install --pre torch torchvision torchaudio --index-url https://download.pytorch.org/whl/nightly/cu128
pip install torch==2.7.0+cu128 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128

pip uninstall -y charset-normalizer
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts charset-normalizer==3.3.2

echo *** VoC - patching typing_extensions
pip uninstall -y typing_extensions
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts typing_extensions==4.11.0

echo *** VoC - patching numpy
pip uninstall -y numpy
pip uninstall -y numpy
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts numpy==1.26.4

call venv\scripts\deactivate.bat
cd ..

rem if not exist model.ckpt goto skip2
rem if not exist FIFO-Diffusion\. md FIFO-Diffusion
rem if not exist FIFO-Diffusion\videocrafter_models\. md FIFO-Diffusion\videocrafter_models
rem if not exist FIFO-Diffusion\videocrafter_models\base_512_v2\. md FIFO-Diffusion\videocrafter_models\base_512_v2
rem echo *** VoC - Restoring model
rem move model.ckpt FIFO-Diffusion\videocrafter_models\base_512_v2\model.ckpt
rem goto skip3

rem :skip2

echo *** Downloading VideoCrafter2 model
cd FIFO-Diffusion
md videocrafter_models
md videocrafter_models\base_512_v2
curl -L -o "videocrafter_models\base_512_v2\model.ckpt" "https://huggingface.co/VideoCrafter/VideoCrafter2/resolve/main/model.ckpt" -v

rem :skip3

echo *** Finished FIFO-Diffusion install
echo.
echo *** Scroll up and check for errors.  Do not assume it worked.
pause


