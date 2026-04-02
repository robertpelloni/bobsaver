@echo off



if exist EdgeTAM\. rd /S /Q EdgeTAM

echo *** %time% *** Cloning EdgeTAM repository
git clone https://github.com/facebookresearch/EdgeTAM.git
cd EdgeTAM

echo *** Creating venv
python -m venv venv
call venv\scripts\activate.bat

echo *** %time% *** Installing requirements
python -m pip install --upgrade pip==24.3.1
pip install wheel
pip install setuptools
pip install -e .
pip install gradio
pip install opencv-python
pip install matplotlib
pip install moviepy==1.0.3
pip install timm
pip install decord

pip uninstall -y torch
pip uninstall -y torch
pip install torch==2.7.0+cu128 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128

cd ..
echo *** %time% VoC *** Finished EdgeTAM install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause
