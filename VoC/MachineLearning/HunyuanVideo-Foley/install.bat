@echo off



echo *** %time% *** Deleting HunyuanVideo-Foley directory if it exists
if exist HunyuanVideo-Foley\. rd /S /Q HunyuanVideo-Foley

echo *** %time% *** Cloning repository
git clone https://github.com/Tencent-Hunyuan/HunyuanVideo-Foley
cd HunyuanVideo-Foley
copy ..\ffmpeg.exe
copy ..\ffprobe.exe

rem echo *** %time% *** Removing flash-attn from requirements.txt
rem type requirements.txt | findstr /v flash-attn > stripped.txt
rem del requirements.txt
rem ren stripped.txt requirements.txt

echo *** %time% *** Creating venv
python -m venv venv

echo *** %time% *** Activating venv
call venv\scripts\activate.bat

echo *** %time% *** Installing requirements
python -m pip install --upgrade pip
pip install -r requirements.txt
pip install huggingface_hub[hf_xet]
pip install spaces

echo *** %time% *** Installing GPU torch
pip uninstall -y torch
pip uninstall -y torch
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.7.0+cu128 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128

echo *** %time% *** Patching pydantic
pip uninstall -y pydantic
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts pydantic==2.10.6


echo *** %time% *** Downloading MovieGenAudioBenchSfx.tar.gz
curl -L -o "assets\MovieGenAudioBenchSfx.tar.gz" "https://d14whct5a0wtwm.cloudfront.net/moviegen/MovieGenAudioBenchSfx.tar.gz" -v
cd assets
..\..\7z.exe x MovieGenAudioBenchSfx.tar.gz
del MovieGenAudioBenchSfx.tar.gz
..\..\7z.exe x MovieGenAudioBenchSfx.tar
del MovieGenAudioBenchSfx.tar
cd..

echo *** %time% *** Downloading examples.tar.gz

curl -L -o "examples.tar.gz" "https://texttoaudio-train-1258344703.cos.ap-guangzhou.myqcloud.com/hunyuanvideo-foley_demo/examples.tar.gz" -v
..\7z.exe x examples.tar.gz
del examples.tar.gz
..\7z.exe x examples.tar
del examples.tar

echo *** %time% *** Downloading models
hf download tencent/HunyuanVideo-Foley

call venv\scripts\deactivate.bat
cd ..
echo *** %time% *** Finished HunyuanVideo-Foley install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause
