@echo off



if exist dia\. rd /S /Q dia

echo *** %time% *** Cloning Dia repository
git clone https://github.com/nari-labs/dia.git
cd dia

copy..\ffmpeg.exe
copy..\ffprobe.exe

echo *** Creating venv
python -m venv venv
call venv\scripts\activate.bat

echo *** %time% *** Installing requirements
python -m pip install --upgrade pip==24.3.1
pip install wheel
pip install setuptools
pip install -e .
pip uninstall -y torch
pip uninstall -y torch
rem pip install --no-dependencies --pre torch==2.7.0.dev20250311 torchvision torchaudio --index-url https://download.pytorch.org/whl/nightly/cu128
rem pip install --pre torch==2.7.0.dev20250311 torchvision torchaudio --index-url https://download.pytorch.org/whl/nightly/cu128
pip install torch==2.7.0+cu128 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128

echo.
echo *** %time% ***
echo *** %time% *** Note: you can ignore a dependency conflict error above with torchaudio if you see one.
echo *** %time% ***
echo.
cd ..
echo *** %time% VoC *** Finished Dia install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause
