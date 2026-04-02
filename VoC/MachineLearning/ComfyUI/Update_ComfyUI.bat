@echo off




echo *** VoC - Updating local ComfyUI
cd ComfyUI
git pull

rem echo *** Rolling back to commit 772de7c00653fc3a825762f555e836d071a4dc80
rem git reset --hard 772de7c00653fc3a825762f555e836d071a4dc80
rem git clean -df

copy ..\ffmpeg.exe

echo *** VoC - activating virtual environment
call .venv\scripts\activate.bat

echo *** VoC - updating pip
python.exe -m pip install --upgrade pip

rem echo *** Installing xformers
rem pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts xformers==0.0.30

rem echo *** VoC - installing GPU torch
rem pip install torch==2.7.0+cu128 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128

echo *** VoC - installing requirements
pip install -r requirements.txt

echo *** VoC - Cloning ComfyUI Manager
cd custom_nodes
if exist ComfyUI-Manager\. rd /S /Q ComfyUI-Manager
git clone https://github.com/ltdrdata/ComfyUI-Manager.git
if [%1]==[rollback] goto rollback
goto skip
:rollback
echo *** VoC - Rolling ComfyUI Manager back to v3.37.1
rem if this is not done, newer manager >3.37.1 has security checks that stop installs working inside older comfy versions
rem so if user uses the upodate button to rollback comfy then the manager will not install missing nodes
cd ComfyUI-Manager
git checkout 3.37.1
cd..
:skip

echo *** VoC - finished ComfyUI update
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause
