@echo off



echo *** Deleting stable-audio-tools directory if it exists
if exist stable-audio-tools\. rd /S /Q stable-audio-tools

echo *** Cloning stable-audio-tools repository
git clone https://github.com/Stability-AI/stable-audio-tools
cd stable-audio-tools
echo *** Rolling back to commit 6f4e43611ce7734aae85121e22216ca24461b6ff
git reset --hard 6f4e43611ce7734aae85121e22216ca24461b6ff
git clean -df

echo *** Creating venv
python -m venv venv
call venv\scripts\activate.bat

echo *** Installing requirements.txt
pip install wheel
pip install setuptools
rem python.exe -m pip install -U pip wheel setuptools
rem python -m pip install --upgrade pip==24.3.1
python -m pip install --upgrade pip

pip install stable-audio-tools
pip install .

echo *** Installing other required packages

pip install accelerate

pip uninstall -y xformers
pip uninstall -y xformers
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts xformers==0.0.30

pip uninstall -y flash-attn
pip uninstall -y flash-attn
pip install https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/flash_attn-2.7.4.post1-cp310-cp310-win_amd64.whl

pip uninstall -y sageattention
pip uninstall -y sageattention
pip install https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/sageattention-2.1.1+cu128torch2.7.0-cp310-cp310-win_amd64.whl

pip uninstall -y torch
pip uninstall -y torch
pip install torch==2.7.0+cu128 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128

pip install triton-windows

echo *** Patching typing_extensions
pip uninstall -y typing_extensions
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts typing_extensions==4.11.0

echo *** Patching numpy
pip uninstall -y numpy
pip uninstall -y numpy
pip install numpy==1.23.5

echo *** Patching pydantic
pip uninstall -y pydantic
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts pydantic==2.10.6

echo *** Downloading models
md ckpt
curl -L -o "ckpt\ckpt.rar" "https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/SAO.rar" -v

echo *** Extracting models
cd ckpt
..\..\7z x ckpt.rar
del ckpt.rar
cd..

call venv\scripts\deactivate.bat
cd ..

echo *** Finished stable-audio-tools install
echo.
pause
