@echo off
echo *** VoC - Deleting StableTuner directory if it exists
if exist StableTuner\. rd /S /Q StableTuner
echo *** VoC - git clone
git clone https://github.com/devilismyfriend/StableTuner
cd StableTuner
echo *** VoC - git reset
git reset --hard
echo *** VoC - git pull
git pull
echo *** VoC - setting up virtual environment
cd..
mkdir StableTuner\.venv
python -m venv StableTuner/.venv
echo *** VoC - activating virtual environment
call StableTuner\.venv\scripts\activate.bat
echo *** VoC - installing requirements
pip install -r StableTuner\requirements.txt
echo *** VoC - updating pip
python.exe -m pip install --upgrade pip
echo *** VoC - installing wheel
pip install wheel
echo *** VoC - installing diffusers
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts diffusers==0.10.2
echo *** VoC - installing GPU torch
pip uninstall -y torch
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==1.13.1+cu116 torchvision==0.14.1+cu116 torchaudio==0.13.1+cu116 --extra-index-url https://download.pytorch.org/whl/cu116
echo *** VoC - finished StableTuner install


