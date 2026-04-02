@echo off




cd
echo *** Deleting hallo directory if it exists
if exist hallo\. rd /S /Q hallo

echo *** Cloning hallo repository
git clone https://github.com/fudan-generative-vision/hallo
copy ffmpeg.exe hallo\ffmpeg.exe
copy ffprobe.exe hallo\ffprobe.exe
cd hallo

echo *** Creating venv
python -m venv venv
call venv\scripts\activate.bat

echo *** Installing hallo requirements
python -m pip install --upgrade pip==24.3.1
pip install -r requirements.txt
pip install .

echo *** VoC - patching gradio
pip uninstall -y gradio
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts gradio==4.44.1

echo *** VoC - patching huggingface-hub
pip uninstall -y huggingface-hub
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts huggingface-hub==0.25.2

echo *** VoC - patching xformers
pip uninstall -y xformers
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts xformers==0.0.25 --index-url https://download.pytorch.org/whl/cu118

echo *** VoC - installing GPU torch
pip uninstall -y torch
pip uninstall -y torch
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.2.1+cu118 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118

echo *** VoC - patching numpy
pip uninstall -y numpy
pip uninstall -y numpy
pip uninstall -y numpy
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts numpy==1.26.4

echo *** VoC - patching typing_extensions
pip uninstall -y typing_extensions
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts typing_extensions==4.11.0

echo *** VoC - patching pydantic
pip uninstall -y pydantic
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts pydantic==2.10.6

echo *** VoC - downloading models
git lfs install
git clone https://huggingface.co/fudan-generative-ai/hallo pretrained_models

call venv\scripts\deactivate.bat
cd..

echo *** Finished hallo install
echo.
echo *** Scroll up and check for errors.  Do not assume it worked.
pause


