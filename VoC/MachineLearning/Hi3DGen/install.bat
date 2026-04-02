@echo off



if exist Hi3DGen\. rd /S /Q Hi3DGen

echo *** %time% *** Cloning Hi3DGen repository
git clone --recursive https://github.com/Stable-X/Hi3DGen
cd Hi3DGen

echo *** Removing triton from requirements.txt
type requirements.txt | findstr /v triton > stripped.txt
del requirements.txt
ren stripped.txt requirements.txt

echo *** Creating venv
python -m venv venv
call venv\scripts\activate.bat

echo *** %time% *** Installing requirements
python -m pip install --upgrade pip==24.3.1
pip install wheel
pip install setuptools
rem pip install --pre torch torchvision torchaudio --index-url https://download.pytorch.org/whl/nightly/cu128
rem pip install torch==2.4.0 torchvision==0.19.0 --index-url https://download.pytorch.org/whl/cu124
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.7.0+cu128 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128
pip install triton-windows
pip install spconv-cu124==2.3.8
pip install triton-windows
rem pip install xformers==0.0.27.post2
pip install xformers==0.0.30
pip install -r requirements.txt
pip install scikit-image
pip install opencv-python
pip install einops
pip install numpy==1.26.4
pip install hf_xet

cd ..
echo *** %time% VoC *** Finished Hi3DGen install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause
