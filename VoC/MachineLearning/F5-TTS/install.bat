@echo off



cd
echo *** Deleting F5-TTS directory if it exists
if exist F5-TTS\. rd /S /Q F5-TTS

echo *** Cloning F5-TTS repository
git clone https://github.com/SWivid/F5-TTS
copy ffmpeg.exe F5-TTS\ffmpeg.exe
copy ffprobe.exe F5-TTS\ffprobe.exe
cd F5-TTS

echo *** Creating venv
python -m venv venv
call venv\scripts\activate.bat

echo *** Upgrading pip
python -m pip install --upgrade pip==24.3.1
rem pip install pip==23.0.1

echo *** Installing requirements
rem pip install -r requirements.txt
pip install -e .
pip install hf_xet

echo *** Installing GPU Torch
pip uninstall -y torch
pip uninstall -y torch
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.0.1+cu118 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118

echo *** %time% *** Patching charset-normalizer
pip uninstall -y charset-normalizer
pip uninstall -y charset-normalizer
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts charset-normalizer==2.1.1

echo *** VoC - patching typing_extensions
pip uninstall -y typing_extensions
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts typing_extensions==4.11.0

echo *** VoC - patching transformers
pip uninstall -y transformers
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts transformers==4.39.3

echo *** VoC - patching numpy
pip uninstall -y numpy
pip uninstall -y numpy
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts numpy==1.26.4

call venv\scripts\deactivate.bat
cd..

echo *** Finished F5-TTS install
echo.
echo *** Scroll up and check for errors.  Do not assume it worked.
pause
