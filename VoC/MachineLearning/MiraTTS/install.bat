@echo off



echo *** %time% *** Deleting MiraTTS directory if it exists
if exist MiraTTS\. rd /S /Q MiraTTS

echo *** %time% *** Cloning repository
git clone https://github.com/ysharma3501/MiraTTS
cd MiraTTS
copy ..\MiraTTS.py
copy ..\JamesEarlJones.mp3
git clone https://huggingface.co/spaces/Gapeleon/Mira-TTS

echo *** %time% *** Creating venv
python -m venv venv

echo *** %time% *** Activating venv
call venv\scripts\activate.bat

echo *** %time% *** Upgrading pip
rem python -m pip install -U pip
rem python -m pip install pip==24.0
python.exe -m pip install --upgrade pip
pip install wheel==0.45.1
pip install setuptools==65.5.0
pip install ninja==1.11.1.4

echo *** %time% *** Installing MiraTTS
pip install git+https://github.com/ysharma3501/MiraTTS.git
pip install omegaconf
pip install IPython
pip install hf_xet
pip install gradio
pip install spaces

echo *** %time% *** Installing GPU torch
pip uninstall -y torch
pip uninstall -y torch
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.7.0+cu128 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128

rem echo *** %time% *** Patching numpy
rem pip uninstall -y numpy
rem pip uninstall -y numpy
rem pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts numpy==1.26.4

call venv\scripts\deactivate.bat
cd ..
echo *** %time% *** Finished MiraTTS install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause
