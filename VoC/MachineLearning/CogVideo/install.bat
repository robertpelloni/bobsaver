@echo off



echo *** %time% *** Deleting CogVideo directory if it exists
if exist CogVideo\. rd /S /Q CogVideo

echo *** %time% *** Cloning CogVideo repository
git clone https://github.com/THUDM/CogVideo
cd CogVideo

echo *** Removing streamlit from requirements.txt
type requirements.txt | findstr /v streamlit > stripped.txt
del requirements.txt
ren stripped.txt requirements.txt

echo *** Removing gradio from requirements.txt
type requirements.txt | findstr /v gradio > stripped.txt
del requirements.txt
ren stripped.txt requirements.txt

echo *** Removing torch from requirements.txt
type requirements.txt | findstr /v torch > stripped.txt
del requirements.txt
ren stripped.txt requirements.txt

echo *** Removing torchvision from requirements.txt
type requirements.txt | findstr /v torchvision > stripped.txt
del requirements.txt
ren stripped.txt requirements.txt

echo *** Removing opencv-python from requirements.txt
type requirements.txt | findstr /v opencv-python > stripped.txt
del requirements.txt
ren stripped.txt requirements.txt

echo *** %time% *** Creating venv
python -m venv venv

echo *** %time% *** Activating venv
call venv\scripts\activate.bat

echo *** %time% *** Installing requirements
python -m pip install --upgrade pip==24.3.1
pip install https://softology.pro/wheels/deepspeed-0.12.7+40342055-py3-none-any.whl
pip install -r requirements.txt
pip install opencv-python
pip install gradio
pip install imageio
pip install moviepy

echo *** %time% *** Patching xformers
pip uninstall -y xformers
rem pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts xformers==0.0.27.post2 --index-url https://download.pytorch.org/whl/cu121
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts xformers==0.0.30

echo *** %time% *** Installing GPU torch
pip uninstall -y torch
pip uninstall -y torch
rem pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.4.0+cu121 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.7.0+cu128 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128

echo *** VoC - patching typing_extensions
pip uninstall -y typing_extensions
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts typing_extensions==4.11.0

call venv\scripts\deactivate.bat
cd ..
echo *** %time% *** Finished CogVideo install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause
