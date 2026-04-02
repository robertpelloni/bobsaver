@echo off



echo *** %time% *** Deleting CogVideo directory if it exists
if exist CogVideo\. rd /S /Q CogVideo

echo *** %time% *** Cloning Cogvideo repository
git clone https://github.com/THUDM/CogVideo
cd CogVideo

echo *** %time% *** Creating venv
python -m venv venv

echo *** %time% *** Activating venv
call venv\scripts\activate.bat

echo *** %time% *** Installing requirements
python -m pip install --upgrade pip==24.3.1
pip install https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/deepspeed-0.12.7+40342055-py3-none-any.whl

pip install -r requirements.txt
pip install moviepy==2.0.0.dev2
pip install spandrel
pip install opencv-python
pip install scikit-video
pip install https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/triton-3.0.0-cp310-cp310-win_amd64.whl

echo *** %time% *** Patching xformers
pip uninstall -y xformers
rem pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts xformers==0.0.27.post2 --index-url https://download.pytorch.org/whl/cu121
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts xformers==0.0.30

echo *** %time% *** Installing GPU torch
pip uninstall -y torch
pip uninstall -y torch
rem pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.4.0+cu121 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.7.0+cu128 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128

echo *** VoC - patching typing_extensions
pip uninstall -y typing_extensions
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts typing_extensions==4.11.0

echo *** VoC - patching triton
pip uninstall -y triton
pip install triton-windows

echo *** %time% *** Downloading Cogstudio script
curl -L -o inference\gradio_composite_demo\cogstudio.py https://raw.githubusercontent.com/pinokiofactory/cogstudio/refs/heads/main/cogstudio.py -v

call venv\scripts\deactivate.bat
cd ..
echo *** %time% *** Finished Cogstudio install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause
