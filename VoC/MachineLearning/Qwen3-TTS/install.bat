@echo off



echo *** %time% *** Deleting Qwen3-TTS directory if it exists
if exist Qwen3-TTS\. rd /S /Q Qwen3-TTS

echo *** %time% *** Cloning repository
git clone https://github.com/QwenLM/Qwen3-TTS
cd Qwen3-TTS
copy ..\app.py
copy ..\ffmpeg.exe
copy ..\ffprobe.exe

echo *** %time% *** Creating venv
python -m venv venv

echo *** %time% *** Activating venv
call venv\scripts\activate.bat

echo *** %time% *** Upgrading pip
python.exe -m pip install --upgrade pip
pip install wheel==0.45.1
pip install setuptools==65.5.0
pip install ninja==1.11.1.4

echo *** %time% *** Installing requirements
pip install -e .
pip install spaces

echo *** %time% *** Installing GPU torch
pip uninstall -y torch
pip uninstall -y torch
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.7.0+cu128 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128

echo *** %time% *** Installing more requirements
pip install torchtext
pip install https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/flash_attn-2.7.4.post1-cp310-cp310-win_amd64.whl
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts triton-windows==3.5.0.post21
pip install gradio
pip uninstall -y transformers
pip install transformers==4.57.3

rem pip uninstall -y click
rem pip install click==7.0

echo *** %time% *** Downloading models
pip install hf_xet
rem pip install -U "huggingface_hub[cli]"
hf download Qwen/Qwen3-TTS-Tokenizer-12Hz --local-dir ./Qwen3-TTS-Tokenizer-12Hz
hf download Qwen/Qwen3-TTS-12Hz-1.7B-CustomVoice --local-dir ./Qwen3-TTS-12Hz-1.7B-CustomVoice
hf download Qwen/Qwen3-TTS-12Hz-1.7B-VoiceDesign --local-dir ./Qwen3-TTS-12Hz-1.7B-VoiceDesign
hf download Qwen/Qwen3-TTS-12Hz-1.7B-Base --local-dir ./Qwen3-TTS-12Hz-1.7B-Base
hf download Qwen/Qwen3-TTS-12Hz-0.6B-CustomVoice --local-dir ./Qwen3-TTS-12Hz-0.6B-CustomVoice
hf download Qwen/Qwen3-TTS-12Hz-0.6B-Base --local-dir ./Qwen3-TTS-12Hz-0.6B-Base

call venv\scripts\deactivate.bat
cd ..
echo *** %time% *** Finished Qwen3-TTS install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause
