@echo off
cls



echo *** VoC - Deleting FramePack directory if it exists
if exist FramePack. rd /S /Q FramePack

echo *** VoC - Downloading zip
rem curl -L -o FramePack.7z https://github.com/lllyasviel/FramePack/releases/download/windows/framepack_cu126_torch26.7z -v
curl -L -o FramePack.7z https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/framepack_cu126_torch26.7z -v

echo *** VoC - Extracting zip
7z x FramePack.7z
ren framepack_cu126_torch26 FramePack
del FramePack.7z

echo *** VoC - Patching embedded Python environment
set "PATH=%CD%\FramePack\system\python\Scripts;%PATH%"
echo %PATH%
cd FramePack\system
.\python\python.exe -s -m pip install --upgrade pip
.\python\python.exe -s -m pip install -r ..\webui\requirements.txt
.\python\python.exe -s -m pip uninstall -y torch
.\python\python.exe -s -m pip install flatbuffers
.\python\python.exe -s -m pip install torch==2.7.0+cu128 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128
.\python\python.exe -s -m pip install xformers==0.0.30
.\python\python.exe -s -m pip install https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/sageattention-2.1.1+cu128torch2.7.0-cp310-cp310-win_amd64.whl
.\python\python.exe -s -m pip install https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/flash_attn-2.7.4.post1-cp310-cp310-win_amd64.whl
.\python\python.exe -s -m pip install triton-windows==3.5.0.post21
.\python\python.exe -s -m pip install hf_xet

echo.
echo *** VoC - finished FramePack install

echo.
echo *** Scroll up and check for any error messages.  Do not assume the install worked. ***
pause
