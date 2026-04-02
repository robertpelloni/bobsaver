@echo off



cd
echo *** Deleting LHM directory if it exists
if exist LHM\. rd /S /Q LHM

echo *** Cloning LHM repository
git lfs install
git clone https://github.com/aigc3d/LHM
cd LHM
git reset --hard c6fa1b8fd9f59089f80e36311b8fd49f5c62da73
git clean -df

echo *** Creating venv
python -m venv venv
call venv\scripts\activate.bat

echo *** Upgrading pip
python -m pip install --upgrade pip==24.3.1
pip install wheel

echo *** Patching install_cu121.bat
findstr /V "pause" install_cu121.bat > patched.txt
del install_cu121.bat
ren patched.txt install_cu121.bat
findstr /V "completed" install_cu121.bat > patched.txt
del install_cu121.bat
ren patched.txt install_cu121.bat

echo *** Installing LHM
call install_cu121.bat
pip install https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/triton-3.0.0-cp310-cp310-win_amd64.whl

echo *** Patching gradio
pip uninstall -y gradio
pip uninstall -y gradio-client
pip install gradio==5.23.1

echo *** Downloading models
curl -L -o "LHM_prior_model.tar" https://virutalbuy-public.oss-cn-hangzhou.aliyuncs.com/share/aigc3d/data/LHM/LHM_prior_model.tar -v
curl -L -o "motion_video.tar" https://virutalbuy-public.oss-cn-hangzhou.aliyuncs.com/share/aigc3d/data/LHM/motion_video.tar -v

echo *** Extracting models
..\7z x LHM_prior_model.tar
..\7z x motion_video.tar
del LHM_prior_model.tar
del motion_video.tar

call venv\scripts\deactivate.bat
cd..

echo *** Finished LHM install
echo.
echo *** Scroll up and check for errors.  Do not assume it worked.
pause
