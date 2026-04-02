@echo off



echo *** %time% *** Deleting HelloMeme directory if it exists
if exist HelloMeme\. rd /S /Q HelloMeme

echo *** %time% *** Cloning HelloMeme repository
git clone https://github.com/HelloVision/HelloMeme
copy ffmpeg.exe HelloMeme\ffmpeg.exe
copy ffprobe.exe HelloMeme\ffprobe.exe
cd HelloMeme

echo *** %time% *** Creating venv
python -m venv venv

echo *** %time% *** Activating venv
call venv\scripts\activate.bat

echo *** %time% *** Installing requirements
python -m pip install --upgrade pip==24.3.1
rem pip install transformers einops scipy opencv-python tqdm pillow onnxruntime onnx safetensors accelerate peft
rem pip install gradio
rem pip install imageio[ffmpeg]
pip install -r requirements.txt
pip install hf_xet

echo *** %time% *** Installing GPU torch
pip uninstall -y torch
pip uninstall -y torch
rem pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.4.1+cu121 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.7.0+cu128 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128

rem echo *** %time% *** Installing Diffusers
rem pip install diffusers==0.30.3

rem echo *** %time% *** Patching opencv-python
rem pip uninstall -y opencv-python
rem pip install opencv-python==4.9.0.80

echo *** %time% *** Patching numpy
pip uninstall -y numpy
pip uninstall -y numpy
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts numpy==1.26.4

echo *** %time% *** Patching typing_extensions
pip uninstall -y typing_extensions
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts typing_extensions==4.11.0

call venv\scripts\deactivate.bat
cd ..
echo *** %time% *** Finished HelloMeme install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause
