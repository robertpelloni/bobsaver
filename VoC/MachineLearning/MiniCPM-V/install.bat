@echo off



cd
echo *** Deleting MiniCPM-V directory if it exists
if exist MiniCPM-V\. rd /S /Q MiniCPM-V

echo *** Cloning MiniCPM-V repository
git clone https://github.com/OpenBMB/MiniCPM-V.git
cd MiniCPM-V

echo *** Creating venv
python -m venv venv
call venv\scripts\activate.bat

echo *** %time% *** Removing spacy from requirements.txt
type requirements.txt | findstr /v spacy > stripped.txt
del requirements.txt
ren stripped.txt requirements.txt

echo *** %time% *** Removing gradio from requirements.txt
type requirements.txt | findstr /v gradio > stripped.txt
del requirements.txt
ren stripped.txt requirements.txt

echo *** %time% *** Removing transformers from requirements.txt
type requirements.txt | findstr /v transformers > stripped.txt
del requirements.txt
ren stripped.txt requirements.txt

echo *** Installing requirments
python -m pip install --upgrade pip==24.3.1
pip install -r requirements.txt
pip install transformers
pip install spacy
pip install gradio
pip install gradio_client
rem pip install https://softology.pro/wheels/flash_attn-2.6.3-cp310-cp310-win_amd64.whl
pip install https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/flash_attn-2.7.4.post1-cp310-cp310-win_amd64.whl

echo *** Installing GPU Torch
pip uninstall -y torch
pip uninstall -y torch
rem pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.2.1+cu118 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
rem pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.4.0+cu121 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.7.0+cu128 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128

echo *** VoC - patching typing_extensions
pip uninstall -y typing_extensions
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts typing_extensions==4.11.0

call venv\scripts\deactivate.bat

cd ..

echo *** Finished MiniCPM-V install
echo.
echo *** Scroll up and check for errors.  Do not assume it worked.
pause


