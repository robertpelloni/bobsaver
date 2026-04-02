@echo off



cd
echo *** Deleting StableDiffusionWebUI directory if it exists
if exist StableDiffusionWebUI\. rd /S /Q StableDiffusionWebUI

echo *** Cloning stable-diffusion-webui repository
git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui
ren stable-diffusion-webui StableDiffusionWebUI
cd StableDiffusionWebUI

echo *** Creating venv
python -m venv venv
call venv\scripts\activate.bat

echo *** Upgrading pip
python -m pip install --upgrade pip
pip install wheel
pip install setuptools

echo *** Installing requirements
pip install -r requirements_versions.txt

rem pip install https://softology.pro/wheels/triton-3.0.0-cp310-cp310-win_amd64.whl
pip install spaces
pip install hf-xet
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts xformers==0.0.30
pip install clip


echo *** Installing GPU Torch
pip uninstall -y torch
pip uninstall -y torch
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.7.0+cu128 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128

echo *** %time% *** Patching numpy
pip uninstall -y numpy
pip uninstall -y numpy
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts numpy==1.26.4

rem echo *** %time% *** Patching charset-normalizer
rem pip uninstall -y charset-normalizer
rem pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts charset-normalizer==3.3.2

call venv\scripts\deactivate.bat
cd..

echo *** Finished StableDiffusionWebUI install
echo.
echo *** Scroll up and check for errors.  Do not assume it worked.
pause
