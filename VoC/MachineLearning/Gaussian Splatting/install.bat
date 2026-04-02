@echo off
cls
D:
cd "D:\code\Delphi\Chaos\Examples\MachineLearning\Gaussian Splatting\"

echo *** VoC - Deleting gaussian-splatting directory if it exists
if exist gaussian-splatting. rd /S /Q gaussian-splatting

echo *** VoC - Deleting .venv directory if it exists
if exist .venv\. rd /S /Q .venv
echo *** VoC - setting up virtual environment
python -m venv .venv
echo *** VoC - activating virtual environment
call .venv\scripts\activate.bat

echo *** VoC - git clone gaussian-splatting
git clone https://github.com/graphdeco-inria/gaussian-splatting
cd gaussian-splatting

echo *** VoC - upgrading pip
python.exe -m pip install --upgrade pip

echo *** VoC - installing requirements
python -m pip install --upgrade pip==24.3.1
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts wheel==0.38.4
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts plyfile==0.8.1
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts tqdm==4.66.1
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==1.13.1+cu116 torchvision==0.14.1+cu116 torchaudio==0.13.1+cu116 --extra-index-url https://download.pytorch.org/whl/cu116
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts git+https://github.com/graphdeco-inria/diff-gaussian-rasterization@59f5f77e3ddbac3ed9db93ec2cfe99ed6c5d121d
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts git+https://gitlab.inria.fr/bkerbl/simple-knn.git@44f764299fa305faf6ec5ebd99939e0508331503

echo *** VoC - patching typing_extensions
pip uninstall -y typing_extensions
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts typing_extensions==4.11.0

echo *** VoC - downloading COLMAP
curl -L -o "COLMAP-3.8-windows-cuda.zip" "https://github.com/colmap/colmap/releases/download/3.8/COLMAP-3.8-windows-cuda.zip" -v

echo *** VoC - unzipping COLMAP
..\7z.exe x COLMAP-3.8-windows-cuda.zip
del COLMAP-3.8-windows-cuda.zip
move COLMAP-3.8-windows-cuda COLMAP

echo *** VoC - downloading viewers
curl -L -o "viewers.zip" "https://repo-sam.inria.fr/fungraph/3d-gaussian-splatting/binaries/viewers.zip" -v

echo *** VoC - unzipping viewers
..\7z.exe x viewers.zip -oviewers
del viewers.zip

echo *** finished gaussian-splatting install

echo.
echo *** Scroll up and check for any error messages.  Do not assume the install worked. ***
pause
