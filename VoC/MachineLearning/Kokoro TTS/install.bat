@echo off



if exist kokoro-tts\. rd /S /Q kokoro-tts

echo *** %time% *** Cloning Kokoro-TTS repository
git clone --recursive https://github.com/nazdridoy/kokoro-tts.git
cd kokoro-tts

echo *** Creating venv
python -m venv venv
call venv\scripts\activate.bat

echo *** %time% *** Installing requirements
python -m pip install --upgrade pip==24.3.1
pip install wheel
rem del requirements.txt
rem copy ..\requirements.txt
rem pip install -r requirements.txt
pip install -e .

echo *** %time% - Installing GPU torch
pip uninstall -y xformers
pip uninstall -y torch
pip uninstall -y torch
rem xformers can be installed with torch
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.6.0+cu124 torchvision torchaudio xformers --index-url https://download.pytorch.org/whl/cu124


echo *** %time% - Downloading models
curl -L -o voices-v1.0.bin https://github.com/nazdridoy/kokoro-tts/releases/download/v1.0.0/voices-v1.0.bin -v
curl -L -o kokoro-v1.0.onnx https://github.com/nazdridoy/kokoro-tts/releases/download/v1.0.0/kokoro-v1.0.onnx -v

cd ..
echo *** %time% VoC *** Finished Kokoro TTS install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause
