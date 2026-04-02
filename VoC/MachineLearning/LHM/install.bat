@echo off



cd
echo *** Deleting LHM directory if it exists
if exist LHM\. rd /S /Q LHM

echo *** Cloning LHM repository
git lfs install
git clone https://github.com/aigc3d/LHM
cd LHM
rem git reset --hard c6fa1b8fd9f59089f80e36311b8fd49f5c62da73
rem git clean -df

echo *** Creating venv
python -m venv venv
call venv\scripts\activate.bat

echo *** Upgrading pip
python -m pip install --upgrade pip==24.3.1
pip install wheel
pip install setuptools
pip install ninja

echo *** Patching install_cu121.bat
findstr /V "pytorch3d" install_cu121.bat > patched.txt
del install_cu121.bat
ren patched.txt install_cu121.bat
findstr /V "pause" install_cu121.bat > patched.txt
del install_cu121.bat
ren patched.txt install_cu121.bat
findstr /V "completed" install_cu121.bat > patched.txt
del install_cu121.bat
ren patched.txt install_cu121.bat

echo *** Installing LHM
call install_cu121.bat

echo *** Patching gradio
pip uninstall -y gradio
pip uninstall -y gradio-client
pip install gradio==5.23.1

echo *** Installing triton
pip install https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/triton-3.0.0-cp310-cp310-win_amd64.whl

rem this pytorch3d install fails during the install
rem BUT if the same command is run from a command prompt after activating the venv it works?!
echo *** Installing pytorch3d
rem pip install "git+https://github.com/facebookresearch/pytorch3d.git@stable" --no-build-isolation
pip install "git+https://github.com/facebookresearch/pytorch3d.git@stable"

echo *** Downloading models
curl -L -o "LHM_prior_model.tar" https://virutalbuy-public.oss-cn-hangzhou.aliyuncs.com/share/aigc3d/data/LHM/LHM_prior_model.tar -v
curl -L -o "motion_video.tar" https://virutalbuy-public.oss-cn-hangzhou.aliyuncs.com/share/aigc3d/data/LHM/motion_video.tar -v
curl -L -o "LHM_ComfyUI.zip" https://virutalbuy-public.oss-cn-hangzhou.aliyuncs.com/share/aigc3d/data/LHM/ComfyUI/LHM_ComfyUI.zip -v

echo *** Extracting models
..\7z x LHM_prior_model.tar
..\7z x motion_video.tar
..\7z x LHM_ComfyUI.zip -y
del LHM_prior_model.tar
del motion_video.tar
del LHM_ComfyUI.zip

call venv\scripts\deactivate.bat
cd..

echo *** Finished LHM install
echo.
echo *** Scroll up and check for errors.  Do not assume it worked.
pause
