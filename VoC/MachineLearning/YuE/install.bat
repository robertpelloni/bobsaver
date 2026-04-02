@echo off



cd
echo *** Deleting YuE directory if it exists
if exist YuE\. rd /S /Q YuE

echo *** Cloning llasa-3b-tts repository
git lfs install
git clone https://github.com/multimodal-art-projection/YuE.git
cd YuE/inference/
git clone https://huggingface.co/m-a-p/xcodec_mini_infer
cd ..

echo *** Creating venv
python -m venv venv
call venv\scripts\activate.bat

echo *** Upgrading pip
python -m pip install --upgrade pip==24.3.1

echo *** Installing requirements
pip install -r requirements.txt
rem pip install https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/flash_attn-2.7.1.post1+cu124torch2.5.1cxx11abiFALSE-cp310-cp310-win_amd64.whl
pip install https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/flash_attn-2.7.4.post1-cp310-cp310-win_amd64.whl
pip install https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/triton-3.0.0-cp310-cp310-win_amd64.whl
pip install hf_xet

echo *** Installing GPU Torch
pip uninstall -y torch
pip uninstall -y torch
rem pip install torch==2.5.1+cu124 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124
rem pip install --pre torch torchvision torchaudio --index-url https://download.pytorch.org/whl/nightly/cu128
rem pip install --pre torch==2.7.0.dev20250311 torchvision torchaudio --index-url https://download.pytorch.org/whl/nightly/cu128
pip install torch==2.7.0+cu128 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128

call venv\scripts\deactivate.bat
cd..

echo *** Finished YuE install
echo.
echo *** Scroll up and check for errors.  Do not assume it worked.
pause
