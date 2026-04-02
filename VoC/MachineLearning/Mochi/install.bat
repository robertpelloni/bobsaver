@echo off



echo *** %time% *** Deleting mochi-preview-standalone directory if it exists
if exist mochi-preview-standalone\. rd /S /Q mochi-preview-standalone

echo *** %time% *** Cloning consistory repository
git clone https://github.com/Teravus/mochi-preview-standalone
cd mochi-preview-standalone

echo *** %time% *** Creating venv
python -m venv venv

echo *** %time% *** Activating venv
call venv\scripts\activate.bat

echo *** %time% *** Removing torch from requirements.txt
type requirements.txt | findstr /v torch== > stripped.txt
del requirements.txt
ren stripped.txt requirements.txt

echo *** %time% *** Removing torchaudio from requirements.txt
type requirements.txt | findstr /v torchaudio > stripped.txt
del requirements.txt
ren stripped.txt requirements.txt

echo *** %time% *** Removing torchvision from requirements.txt
type requirements.txt | findstr /v torchvision > stripped.txt
del requirements.txt
ren stripped.txt requirements.txt

echo *** %time% *** Installing requirements
python -m pip install --upgrade pip==24.3.1
pip install -r requirements.txt
pip install https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/triton-3.0.0-cp310-cp310-win_amd64.whl

echo *** %time% *** Installing xformers
pip uninstall -y xformers
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts xformers==0.0.27

echo *** %time% *** Installing GPU torch
pip uninstall -y torch
pip uninstall -y torch
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.3.1+cu121 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121

rem echo *** %time% *** Patching huggingface-hub
rem pip uninstall -y huggingface-hub
rem pip install huggingface-hub==0.25.0

echo *** VoC - patching typing_extensions
pip uninstall -y typing_extensions
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts typing_extensions==4.11.0

echo *** %time% *** Downloading models
curl -L -o "models\mochi\mochi_preview_dit_fp8_e4m3fn.safetensors" "https://huggingface.co/Kijai/Mochi_preview_comfy/resolve/main/mochi_preview_dit_fp8_e4m3fn.safetensors" -v
curl -L -o "models\vae\mochi\mochi_preview_vae_decoder_bf16.safetensors" "https://huggingface.co/Kijai/Mochi_preview_comfy/resolve/main/mochi_preview_vae_decoder_bf16.safetensors" -v
curl -L -o "models\clip\t5xxl_fp16.safetensors" "https://huggingface.co/comfyanonymous/flux_text_encoders/resolve/main/t5xxl_fp16.safetensors" -v

call venv\scripts\deactivate.bat
cd ..
echo *** %time% *** Finished Mochi Standalone install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause
