@echo off



if exist Step1X-Edit\. rd /S /Q Step1X-Edit

echo *** %time% *** Cloning Step1X-Edit repository
git clone https://github.com/stepfun-ai/Step1X-Edit
cd Step1X-Edit

echo *** Creating venv
python -m venv venv
call venv\scripts\activate.bat

echo *** %time% *** Stripping liger from requirements.txt
type requirements.txt | findstr /v liger > stripped.txt
del requirements.txt
ren stripped.txt requirements.txt

echo *** %time% *** Stripping transformers from requirements.txt
type requirements.txt | findstr /v transformers > stripped.txt
del requirements.txt
ren stripped.txt requirements.txt

echo *** %time% *** Installing requirements
python -m pip install --upgrade pip==24.3.1
pip install wheel
pip install setuptools
pip install -r requirements.txt
pip install liger_kernel==0.5.4 --no-deps
pip install transformers==4.55.0
pip install https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/flash_attn-2.7.4.post1-cp310-cp310-win_amd64.whl
pip uninstall -y torch
pip uninstall -y torch
pip install torch==2.7.0+cu128 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128

echo *** %time% *** NOTE: you can ignore the above dependency conflict if you see one

pip install triton-windows

echo *** %time% *** Downloading models
md models
curl -L -o "models\step1x-edit-i1258-FP8.safetensors" "https://huggingface.co/meimeilook/Step1X-Edit-FP8/resolve/main/step1x-edit-i1258-FP8.safetensors" -v
curl -L -o "models\vae.safetensors" "https://huggingface.co/meimeilook/Step1X-Edit-FP8/resolve/main/vae.safetensors" -v

cd ..
echo *** %time% VoC *** Finished Step1X-Edit install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause
