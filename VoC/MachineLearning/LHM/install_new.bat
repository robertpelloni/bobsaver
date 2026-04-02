@echo off



cd
echo *** Deleting LHM directory if it exists
if exist LHM\. rd /S /Q LHM

echo *** Cloning LHM repository
git lfs install
git clone https://github.com/aigc3d/LHM
cd LHM

echo *** Creating venv
python -m venv venv
call venv\scripts\activate.bat

echo *** Upgrading pip
python -m pip install --upgrade pip
pip install wheel
pip install setuptools
pip install ninja

echo *** Removing chumpy from requirements.txt
cd ComfyUI\custom_nodes\LHM
type requirements.txt | findstr /v chumpy > stripped.txt
del requirements.txt
ren stripped.txt requirements.txt

echo *** Installing requirements
pip install -r requirements.txt
pip install chumpy --no-build-isolation
pip install onnxruntime
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts xformers==0.0.30

echo *** Installing GPU torch
pip uninstall -y torch
pip uninstall -y torch
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.7.0+cu128 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128

echo Patching basicsr to avoid conflicts...
pip uninstall -y basicsr
pip install git+https://github.com/XPixelGroup/BasicSR

echo Installing sam2...
pip install git+https://github.com/hitsz-zuoqi/sam2/

echo Installing diff-gaussian-rasterization...
pip install git+https://github.com/ashawkey/diff-gaussian-rasterization/ --no-build-isolation

echo Installing simple-knn...
pip install git+https://github.com/camenduru/simple-knn/ --no-build-isolation

echo *** Installing pytorch3d
pip install "git+https://github.com/facebookresearch/pytorch3d.git@stable" --no-build-isolation

rem echo *** Patching numpy
rem pip uninstall -y numpy
rem pip uninstall -y numpy
rem pip install numpy==1.26.4

rem echo *** Downloading models
rem curl -L -o "LHM_prior_model.tar" https://virutalbuy-public.oss-cn-hangzhou.aliyuncs.com/share/aigc3d/data/LHM/LHM_prior_model.tar -v
rem curl -L -o "motion_video.tar" https://virutalbuy-public.oss-cn-hangzhou.aliyuncs.com/share/aigc3d/data/LHM/motion_video.tar -v
rem curl -L -o "LHM_ComfyUI.zip" https://virutalbuy-public.oss-cn-hangzhou.aliyuncs.com/share/aigc3d/data/LHM/ComfyUI/LHM_ComfyUI.zip -v

rem echo *** Extracting models
rem ..\7z x LHM_prior_model.tar
rem ..\7z x motion_video.tar
rem ..\7z x LHM_ComfyUI.zip -y
rem del LHM_prior_model.tar
rem del motion_video.tar
rem del LHM_ComfyUI.zip

call venv\scripts\deactivate.bat
cd..

echo *** Finished LHM install
echo.
echo *** Scroll up and check for errors.  Do not assume it worked.
pause
