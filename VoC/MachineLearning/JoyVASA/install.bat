@echo off



echo *** %time% *** Deleting JoyVASA directory if it exists
if exist JoyVASA\. rd /S /Q JoyVASA

echo *** %time% *** Cloning JoyVASA repository
git clone https://github.com/jdh-algo/JoyVASA
copy ffmpeg.exe JoyVASA\ffmpeg.exe
copy ffprobe.exe JoyVASA\ffprobe.exe
cd JoyVASA

echo *** %time% *** Removing mediapipe from requirements.txt
type requirements.txt | findstr /v mediapipe > stripped.txt
del requirements.txt
ren stripped.txt requirements.txt

echo *** %time% *** Creating venv
python -m venv venv

echo *** %time% *** Activating venv
call venv\scripts\activate.bat

echo *** %time% *** Installing requirements
python -m pip install --upgrade pip==24.3.1
pip install wheel
pip install setuptools
pip install -r requirements.txt
pip install huggingface_hub[cli]
pip install mediapipe
pip install hf_xet

echo *** %time% *** Installing GPU torch
pip uninstall -y torch
rem pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.4.1+cu118 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.7.0+cu128 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128

echo *** %time% *** Patching typing_extensions
pip uninstall -y typing_extensions
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts typing_extensions==4.11.0

echo *** %time% *** Patching pydantic
pip uninstall -y pydantic
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts pydantic==2.10.6

echo *** %time% *** Installing XPose
pip install https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/MultiScaleDeformableAttention-1.0-cp310-cp310-win_amd64.whl
rem cd src/utils/dependencies/XPose/models/UniPose/ops
rem python setup.py build install
rem cd..
rem cd..
rem cd..
rem cd..
rem cd..
rem cd..
rem cd..

echo *** %time% *** Downloading models
md pretrained_weights
cd pretrained_weights
git lfs install
git clone https://huggingface.co/jdh-algo/JoyVASA
git clone https://huggingface.co/TencentGameMate/chinese-hubert-base
git clone https://huggingface.co/facebook/wav2vec2-base-960h
cd..
huggingface-cli download KwaiVGI/LivePortrait --local-dir pretrained_weights --exclude "*.git*" "README.md" "docs"

call venv\scripts\deactivate.bat
cd ..
echo *** %time% *** Finished JoyVASA install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause
