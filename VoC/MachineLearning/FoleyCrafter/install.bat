@echo off



echo *** %time% VoC *** Deleting FoleyCrafter directory if it exists
if exist FoleyCrafter\. rd /S /Q FoleyCrafter

echo *** %time% VoC *** Cloning FoleyCrafter repository
git clone https://github.com/open-mmlab/FoleyCrafter
cd FoleyCrafter

echo *** %time% VoC *** Creating venv
python -m venv venv

echo *** %time% VoC *** Activating venv
call venv\scripts\activate.bat

echo *** %time% VoC *** Installing requirments
python -m pip install -U pip
python -m pip install pip==24.0

pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts diffusers==0.25.1
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts transformers==4.30.2
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts imageio==2.33.1
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts decord==0.6.0
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts einops
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts omegaconf
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts safetensors
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts gradio
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts tqdm==4.66.1
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts soundfile==0.12.1
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts wandb
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts moviepy==1.0.3
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts kornia==0.7.1
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts h5py==3.7.0
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts scipy==1.14.0
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts accelerate==0.32.1
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts matplotlib==3.9.2

echo *** VoC - patching huggingface_hub
pip uninstall -y huggingface_hub
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts huggingface_hub==0.25.0

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
pip uninstall -y pydantic
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts pydantic==2.10.6

call venv\scripts\deactivate.bat
cd ..
echo *** %time% VoC *** Finished FoleyCrafter install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause
