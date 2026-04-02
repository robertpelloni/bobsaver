@echo off



echo *** %time% *** Deleting stable-diffusion-videos directory if it exists
if exist stable-diffusion-videos\. rd /S /Q stable-diffusion-videos

echo *** %time% *** Cloning stable-diffusion-videos repository
git clone https://github.com/nateraw/stable-diffusion-videos
cd stable-diffusion-videos

echo *** %time% *** Creating venv
python -m venv venv

echo *** %time% *** Activating venv
call venv\scripts\activate.bat

echo *** %time% *** Installing requirements
python -m pip install --upgrade pip==24.3.1
pip install stable_diffusion_videos
pip install https://softology.pro/wheels/triton-3.0.0-cp310-cp310-win_amd64.whl
pip install accelerate

echo *** %time% *** Patching xformers
pip uninstall -y xformers
rem pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts xformers==0.0.27.post2 --index-url https://download.pytorch.org/whl/cu121
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts xformers==0.0.30

echo *** %time% *** Installing GPU torch
pip uninstall -y torch
pip uninstall -y torch
rem pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.4.0+cu121 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.7.0+cu128 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128

echo *** %time% *** Patching numpy
pip uninstall -y numpy
pip uninstall -y numpy
pip install numpy==1.26.3
pip install youtube_dl

echo *** VoC - patching typing_extensions
pip uninstall -y typing_extensions
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts typing_extensions==4.11.0

call venv\scripts\deactivate.bat
cd ..
echo *** %time% *** Finished Stable Diffusion Videos install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause
