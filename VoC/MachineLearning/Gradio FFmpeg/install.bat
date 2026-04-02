@echo off



echo *** Deleting gradio-ffmpeg directory if it exists
if exist gradio-ffmpeg\. rd /S /Q gradio-ffmpeg

echo *** Cloning llama3-s repository
git clone --recurse-submodules https://github.com/lazarusking/gradio-ffmpeg
copy ffmpeg.exe gradio-ffmpeg\ffmpeg.exe
copy ffprobe.exe gradio-ffmpeg\ffprobe.exe
cd gradio-ffmpeg

echo *** Creating venv
python -m venv venv
call venv\scripts\activate.bat

echo *** Installing requirments.txt
python -m pip install --upgrade pip==24.3.1
pip install -r requirements.txt

echo *** Installing GPU torch
pip uninstall -y torch
pip uninstall -y torch
rem pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.2.2+cu118 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.7.0+cu128 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128

echo *** VoC - patching typing_extensions
pip uninstall -y typing_extensions
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts typing_extensions==4.11.0

call venv\scripts\deactivate.bat

echo *** Finished Gradio FFmpeg install
echo.
