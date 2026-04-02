@echo off



cd
echo *** Deleting audiblez directory if it exists
if exist audiblez\. rd /S /Q audiblez

echo *** Cloning audiblez repository
git clone https://github.com/santinic/audiblez
copy ffmpeg.exe audiblez\ffmpeg.exe
copy ffprobe.exe audiblez\ffprobe.exe
cd audiblez

echo *** Creating venv
python -m venv venv
call venv\scripts\activate.bat

echo *** Upgrading pip
python -m pip install --upgrade pip==24.3.1

echo *** Installing audiblez
pip install audiblez

echo *** Installing GPU torch
pip uninstall -y torch
pip uninstall -y torch
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.3.1+cu121 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121

echo *** Patching numpy
pip uninstall -y numpy
pip uninstall -y numpy
pip install numpy==1.26.4

call venv\scripts\deactivate.bat
cd..

echo *** Finished audiblez install
echo.
echo *** Scroll up and check for errors.  Do not assume it worked.
pause

