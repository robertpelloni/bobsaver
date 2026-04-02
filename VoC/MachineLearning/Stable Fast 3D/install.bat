@echo off



echo *** %time% *** Deleting stable-fast-3d directory if it exists
if exist stable-fast-3d\. rd /S /Q stable-fast-3d

echo *** %time% *** Cloning stable-fast-3d repository
git clone https://github.com/Stability-AI/stable-fast-3d
cd stable-fast-3d

echo *** %time% *** Creating venv
python -m venv venv

echo *** %time% *** Activating venv
call venv\scripts\activate.bat

echo *** %time% *** Installing GPU torch
python -m pip install --upgrade pip==24.3.1
pip install wheel
rem pip uninstall -y torch
rem pip uninstall -y torch
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.4.0+cu121 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121

echo *** %time% *** Installing requirements
python -m pip install --upgrade pip==24.3.1
pip install wheel
pip install -r requirements.txt
pip install -r requirements-demo.txt
pip install --upgrade huggingface_hub
pip install rembg[gpu]==2.0.57

echo *** %time% *** Patching xformers
pip uninstall -y xformers
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts xformers==0.0.27.post2 --index-url https://download.pytorch.org/whl/cu121

echo *** %time% *** Patching gradio
pip uninstall -y gradio
pip install gradio==4.43.0

rem echo *** %time% *** Installing GPU torch
rem pip uninstall -y torch
rem pip uninstall -y torch
rem pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.4.0+cu121 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121

rem pip uninstall -y charset-normalizer
rem pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts charset-normalizer==3.3.2
rem pip uninstall -y numpy
rem pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts numpy==1.26.4

echo *** VoC - patching typing_extensions
pip uninstall -y typing_extensions
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts typing_extensions==4.11.0

call venv\scripts\deactivate.bat
cd ..
echo *** %time% *** Finished stable-fast-3d install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause
