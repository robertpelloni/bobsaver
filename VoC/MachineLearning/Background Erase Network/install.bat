@echo off



echo *** %time% *** Deleting BEN directory if it exists
if exist BEN2\. rd /S /Q BEN2

echo *** %time% *** Cloning BEN2 repository
git clone https://huggingface.co/PramaLLC/BEN2
cd BEN2
ren inference.py inference_original.py
copy ..\inference.py

echo *** %time% *** Creating venv
python -m venv venv

echo *** %time% *** Activating venv
call venv\scripts\activate.bat

echo *** Removing numpy from requirements.txt
type requirements.txt | findstr /v numpy > stripped.txt
del requirements.txt
ren stripped.txt requirements.txt

echo *** Removing torch from requirements.txt
type requirements.txt | findstr /v torch > stripped.txt
del requirements.txt
ren stripped.txt requirements.txt

echo *** %time% *** Installing requirements
python -m pip install --upgrade pip==24.3.1
pip install -r requirements.txt
pip install opencv-python==4.11.0.86

echo *** %time% *** Installing xformers
rem pip uninstall -y xformers
rem pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts xformers==0.0.27
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts xformers==0.0.30

echo *** %time% *** Installing GPU torch
pip uninstall -y torch
pip uninstall -y torch
rem pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.3.1+cu121 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121
pip install torch==2.7.0+cu128 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128

echo *** VoC - patching typing_extensions
pip uninstall -y typing_extensions
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts typing_extensions==4.11.0

echo *** VoC - patching numpy
pip uninstall -y numpy
pip uninstall -y numpy
rem rd "venv\Lib\site-packages\numpy-2.2.2.dist-info" /s/q
pip install numpy==1.26.4

call venv\scripts\deactivate.bat
cd ..
echo *** %time% *** Finished BEN2 install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause
