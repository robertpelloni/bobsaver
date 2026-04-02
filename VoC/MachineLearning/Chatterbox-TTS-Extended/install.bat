@echo off



echo *** %time% *** Deleting Chatterbox-TTS-Extended directory if it exists
if exist Chatterbox-TTS-Extended\. rd /S /Q Chatterbox-TTS-Extended

echo *** %time% *** Cloning Chatterbox-TTS-Extended repository
git clone https://github.com/petermg/Chatterbox-TTS-Extended
cd Chatterbox-TTS-Extended
copy ..\ffmpeg.exe
copy ..\ffprobe.exe

echo *** %time% *** Creating venv
python -m venv venv

echo *** %time% *** Activating venv
call venv\scripts\activate.bat

echo *** %time% *** Installing requirements
python -m pip install --upgrade pip
pip install -r requirements.base.with.versions.txt

echo *** %time% *** Installing GPU torch
pip uninstall -y torch
pip uninstall -y torch
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.7.0+cu128 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128

rem echo *** %time% *** Patching numpy
rem pip uninstall -y numpy
rem pip uninstall -y numpy
rem pip install numpy==1.26.4

call venv\scripts\deactivate.bat
cd ..
echo *** %time% *** Finished Chatterbox-TTS-Extended install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause
