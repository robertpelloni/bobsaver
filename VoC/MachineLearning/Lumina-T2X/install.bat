@echo off



if not exist Lumina-T2X\models\. goto skip1
echo *** VoC - Backing up existing models
move Lumina-T2X\models models_backup

:skip1

if exist Lumina-T2X\. rd /S /Q Lumina-T2X

echo *** Cloning Lumina-T2X repository
git clone https://github.com/Alpha-VLLM/Lumina-T2X
cd Lumina-T2X

echo *** Creating venv
python -m venv venv
call venv\scripts\activate.bat

echo *** Updating pip
python -m pip install --upgrade pip==24.3.1
pip install wheel

echo *** Installing Lumina-T2X
pip install git+https://github.com/Alpha-VLLM/Lumina-T2X

echo *** Installing other required packages
pip install openai
pip install torchdyn
pip install torchlibrosa
pip install sentencepiece
pip install omegaconf
pip install pytorch_lightning
pip uninstall -y xformers
rem pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts xformers==0.0.25 --index-url https://download.pytorch.org/whl/cu121
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts xformers==0.0.30
pip uninstall -y torch
pip uninstall -y torch
rem pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.2.2+cu121 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121
pip install torch==2.7.0+cu128 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128
pip uninstall -y numpy
pip uninstall -y numpy
pip uninstall -y numpy
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts numpy==1.26.4

echo *** Installing flash-attn
rem pip install https://softology.pro/wheels/flash_attn-2.5.9.post1-cp310-cp310-win_amd64.whl
pip install https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/flash_attn-2.7.4.post1-cp310-cp310-win_amd64.whl

echo *** VoC - patching typing_extensions
pip uninstall -y typing_extensions
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts typing_extensions==4.11.0

call venv\scripts\deactivate.bat
cd ..

if not exist models_backup\. goto skip2
if exist LKumina-T2X\models\. rd /S /Q Lumina-T2X\models
echo *** VoC - Restoring models
move models_backup Lumina-T2X\models

:skip2

echo *** Finished Lumina-T2X install
echo.
echo *** Scroll up and check for any error messages.  Do not assume the install worked. ***
echo.
pause


