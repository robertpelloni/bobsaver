@echo off
cls
D:
cd "D:\code\delphi\Chaos\Examples\MachineLearning\Text To Image\Kubin"

echo *** VoC - Deleting kubin directory if it exists
if exist kubin\. rd /S /Q kubin

echo *** VoC - git clone
git clone https://github.com/seruva19/kubin

cd kubin
copy ..\ffmpeg.exe
copy ..\ffprobe.exe

echo *** VoC - setting up virtual environment
python -m venv .venv
echo *** VoC - activating virtual environment
call .venv\scripts\activate.bat

echo *** VoC - upgrading pip
python.exe -m pip install --upgrade pip

echo *** %time% *** Stripping triton from requirements.txt
type requirements.txt | findstr /v triton > stripped.txt
del requirements.txt
ren stripped.txt requirements.txt

echo *** VoC - installing requirements

rem lock to a specific known working commmit
rem git reset --hard 2729850fb1b5006cc910ac016272dfb1b77716ca

pip install -r requirements.txt

echo *** VoC - installing xformers
rem pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts https://softology.pro/wheels/xformers-0.0.15.dev0+103e863.d20221124-cp310-cp310-win_amd64.whl
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts xformers==0.0.30

pip install https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/flash_attn-2.7.4.post1-cp310-cp310-win_amd64.whl

echo *** VoC - installing GPU torch
pip uninstall -y torch
rem pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==1.13.1+cu116 torchvision==0.14.1+cu116 torchaudio==0.13.1+cu116 --extra-index-url https://download.pytorch.org/whl/cu116
pip install torch==2.7.0+cu128 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128

echo *** VoC - patching typing_extensions
pip uninstall -y typing_extensions
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts typing_extensions==4.11.0

echo *** VoC - patching pydantic
pip uninstall -y pydantic
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts pydantic==2.10.6

pip install triton-windows
pip install ipython
pip install scikit-image
pip install protobuf
pip install hf_xet

echo.
echo *** VoC - finished Kubin install

echo.
echo *** Scroll up and check for any error messages.  Do not assume the install worked. ***
pause
