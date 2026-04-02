@echo off



echo *** %time% *** Deleting fluxgym directory if it exists
if exist fluxgym\. rd /S /Q fluxgym

echo *** %time% *** Cloning fluxgym repository
git clone https://github.com/cocktailpeanut/fluxgym
cd fluxgym

echo *** %time% *** Cloning kohya-ss/sd-scripts repository
git clone -b sd3 https://github.com/kohya-ss/sd-scripts

rem echo *** %time% *** Removing splatting from requirements.txt
rem type requirements.txt | findstr /v splatting > stripped.txt
rem del requirements.txt
rem ren stripped.txt requirements.txt

echo *** %time% *** Creating venv
python -m venv venv

echo *** %time% *** Activating venv
call venv\scripts\activate.bat

echo *** %time% *** Installing requirements
python -m pip install --upgrade pip==24.3.1

echo *** %time% *** Installing requirements
cd sd-scripts
pip install -r requirements.txt
cd..
pip install -r requirements.txt

rem echo *** %time% *** Patching xformers
rem pip uninstall -y xformers
rem pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts xformers==0.0.27.post2 --index-url https://download.pytorch.org/whl/cu121

echo *** %time% *** Installing GPU torch
pip uninstall -y torch
pip uninstall -y torch
rem pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.4.0+cu121 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121
rem pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.3.0+cu121 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121
rem pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.5.1+cu124 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.7.0+cu128 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128

echo *** VoC - patching typing_extensions
pip uninstall -y typing_extensions
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts typing_extensions==4.11.0

echo *** %time% *** Downloading models
cd models
cd clip
curl -L -o clip_l.safetensors https://huggingface.co/comfyanonymous/flux_text_encoders/resolve/main/clip_l.safetensors -v
curl -L -o t5xxl_fp16.safetensors https://huggingface.co/comfyanonymous/flux_text_encoders/resolve/main/t5xxl_fp16.safetensors -v
cd..
cd vae
curl -L -o ae.sft https://huggingface.co/cocktailpeanut/xulf-dev/resolve/main/ae.sft -v
cd..
cd unet
curl -L -o flux1-dev.sft https://huggingface.co/cocktailpeanut/xulf-dev/resolve/main/flux1-dev.sft -v

cd..
cd..
call venv\scripts\deactivate.bat
cd ..
echo *** %time% *** Finished Flux Gym install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause
