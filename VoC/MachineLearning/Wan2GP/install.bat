@echo off



cd
echo *** Deleting Wan2GP directory if it exists
if exist Wan2GP\. rd /S /Q Wan2GP

echo *** Cloning Wan2GP repository
git clone https://github.com/deepbeepmeep/Wan2GP
cd Wan2GP

echo *** Creating venv
python -m venv venv
call venv\scripts\activate.bat

rem echo *** Removing flash_attn from requirements.txt
rem type requirements.txt | findstr /v flash_attn > requirements.txt
rem del requirements.txt
rem ren stripped.txt requirements.txt


echo *** Upgrading pip
python -m pip install -U pip
python -m pip install pip==24.0
pip install wheel==0.45.1
pip install setuptools==65.5.0

echo *** Installing requirements
pip install torch==2.7.0 torchvision torchaudio --index-url https://download.pytorch.org/whl/test/cu128
pip install -r requirements.txt
pip install triton-windows 
pip install sageattention==1.0.6 
pip install hf_xet
pip install https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/sageattention-2.1.1+cu128torch2.7.0-cp310-cp310-win_amd64.whl

echo *** Installing GPU Torch
pip uninstall -y torch
pip uninstall -y torch
pip uninstall -y torch
pip install torch==2.7.0+cu128 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128

rem The next two LoRAs were supposed to 2x speed up generation time.  They don't seem to help at all.
rem echo *** Downloading models
rem ..\wget https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/Wan21_AccVid_T2V_14B_lora_rank32_fp16.safetensors -O "loras\Wan21_AccVid_T2V_14B_lora_rank32_fp16.safetensors" -nc --no-check-certificate
rem ..\wget https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/Wan21_AccVid_I2V_480P_14B_lora_rank32_fp16.safetensors -O "loras_i2v\Wan21_AccVid_I2V_480P_14B_lora_rank32_fp16.safetensors" -nc --no-check-certificate

call venv\scripts\deactivate.bat
cd..

echo *** Finished WanG2P install
echo.
echo *** Scroll up and check for errors.  Do not assume it worked.
pause

:end
