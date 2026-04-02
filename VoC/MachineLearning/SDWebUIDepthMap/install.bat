@echo off



echo *** %time% *** Deleting SDWebUIDepthMap directory if it exists
if exist SDWebUIDepthMap\. rd /S /Q SDWebUIDepthMap
if exist "..\Stable Diffusion Web UI Depthmap\." rd /S /Q "..\Stable Diffusion Web UI Depthmap\."
if exist "..\venv\voc_sdwebuidepthmap\." rd /S /Q "..\venv\voc_sdwebuidepthmap\."

echo *** %time% *** Cloning repository
git clone https://github.com/thygate/stable-diffusion-webui-depthmap-script
ren stable-diffusion-webui-depthmap-script SDWebUIDepthMap
cd SDWebUIDepthMap

echo *** %time% *** Creating venv
python -m venv venv

echo *** %time% *** Activating venv
call venv\scripts\activate.bat

echo *** %time% *** Upgrading pip
python.exe -m pip install --upgrade pip
pip install wheel==0.45.1
pip install setuptools==65.5.0
pip install ninja==1.11.1.4

echo *** %time% *** Installing requirements
pip install -r requirements.txt
pip install einops
pip install transformers
pip install onnxruntime
pip install PyQt5

echo *** %time% *** Installing GPU torch
pip uninstall -y torch
pip uninstall -y torch
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.7.0+cu128 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128

echo *** %time% *** Patching timm
pip uninstall -y timm
pip install timm==0.6.7

echo *** %time% *** Patching numpy
pip uninstall -y numpy
pip uninstall -y numpy
pip install numpy==1.26.4

call venv\scripts\deactivate.bat
cd ..
echo *** %time% *** Finished SDWebUIDepthMap install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause
