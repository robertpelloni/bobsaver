@echo off



if exist LivePortrait\. rd /S /Q LivePortrait

echo *** Cloning LivePortrait repository
git clone https://github.com/KwaiVGI/LivePortrait

copy ffmpeg.exe LivePortrait\ffmpeg.exe
copy ffprobe.exe LivePortrait\ffprobe.exe

cd LivePortrait

echo *** Creating venv
python -m venv venv
call venv\scripts\activate.bat

echo *** Removing triton from requirements.txt
type requirements.txt | findstr /v triton > stripped.txt
del requirements.txt
ren stripped.txt requirements.txt

echo *** Installing requirements.txt
python -m pip install --upgrade pip==24.3.1
pip install -r requirements.txt

echo *** VoC - patching typing_extensions
pip uninstall -y typing_extensions
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts typing_extensions==4.11.0

echo *** VoC - patching pydantic
pip uninstall -y pydantic
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts pydantic==2.10.6

echo *** VoC - installing GPU torch
pip uninstall -y torch
pip uninstall -y torch
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.7.0+cu128 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128

echo *** Downloading models
cd pretrained_weights
curl -L -o weights.rar https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/liveportrait_pretrained_weights.rar -v

echo *** Extracting models
..\..\7z x weights.rar
del weights.rar
cd..

call venv\scripts\deactivate.bat
cd ..

copy ffprobe.exe LivePortrait\ffprobe.exe

echo *** Finished LivePortrait install
echo.
echo *** Check the stats for any errors.  Do not assume it worked.
pause


