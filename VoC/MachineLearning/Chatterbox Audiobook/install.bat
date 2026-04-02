@echo off



echo *** %time% *** Deleting Chatterbox Audiobook directory if it exists
if exist "Chatterbox Audiobook"\. rd /S /Q "Chatterbox Audiobook"

echo *** %time% *** Cloning ChatterboxToolkitUI repository
git clone https://github.com/psdwizzard/chatterbox-Audiobook
ren chatterbox-Audiobook "Chatterbox Audiobook"
cd "Chatterbox Audiobook"
copy ..\ffmpeg.exe
copy ..\ffprobe.exe

echo *** %time% *** Creating venv
python -m venv venv

echo *** %time% *** Activating venv
call venv\scripts\activate.bat

echo *** %time% *** Removing torch from requirements.txt
type requirements.txt | findstr /v torch > stripped.txt
del requirements.txt
ren stripped.txt requirements.txt

echo *** %time% *** Installing requirements
python -m pip install --upgrade pip
pip install -r requirements.txt
pip install omegaconf

echo *** %time% *** Installing GPU torch
pip uninstall -y torch
pip uninstall -y torch
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.7.0+cu128 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128

echo *** %time% *** Patching numpy
pip uninstall -y numpy
pip uninstall -y numpy
pip install numpy==1.26.4

call venv\scripts\deactivate.bat
cd ..
echo *** %time% *** Finished Chatterbox Audiobook install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause
