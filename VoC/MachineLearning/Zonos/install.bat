@echo off




if exist "C:\Program Files\eSpeak NG\libespeak-ng.dll" goto skip
echo *** Installing espeak-ng.  Accept the default settings.
echo *** espeak-ng is required for Zonos to work.
cmd.exe /c espeak-ng.msi
goto next
:skip
echo *** espeak-ng already installed.  Skipping espeak-ng installation.
:next

echo *** %time% VoC *** Deleting Zonos-for-windows directory if it exists
if exist Zonos-for-windows\. rd /S /Q Zonos-for-windows

echo *** %time% VoC *** Cloning Zonos-for-windows repository
git clone https://github.com/sdbds/Zonos-for-windows
cd Zonos-for-windows

echo *** Creating venv
python -m venv venv
call venv\scripts\activate.bat

echo *** %time% *** Removing torch from requirements-uv.txt
type requirements-uv.txt | findstr /v torch > stripped.txt
del requirements-uv.txt
ren stripped.txt requirements-uv.txt

echo *** %time% *** Installing requirements
python -m pip install --upgrade pip==24.3.1
pip install -r requirements-uv.txt
pip install https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/flash_attn-2.7.4.post1-cp310-cp310-win_amd64.whl

echo *** VoC - Installing GPU torch
pip uninstall -y torch
pip uninstall -y torch
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.7.0+cu128 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128

cd ..
echo *** %time% VoC *** Finished Zonos-for-windows install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause
