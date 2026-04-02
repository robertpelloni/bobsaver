@echo off



echo *** %time% VoC *** Deleting AniTalker directory if it exists
if exist AniTalker\. rd /S /Q AniTalker

echo *** %time% VoC *** Cloning AniTalker repository
git clone https://github.com/X-LANCE/AniTalker/
copy ffmpeg.exe AniTalker\ffmpeg.exe
copy ffprobe.exe AniTalker\ffprobe.exe
cd AniTalker

echo *** %time% VoC *** Creating venv
python -m venv venv

echo *** %time% VoC *** Activating venv
call venv\scripts\activate.bat

echo *** Removing scipy from requirements_windows
findstr /V "scipy" requirements_windows.txt > requirements_patched.txt
del requirements_windows.txt
ren requirements_patched.txt requirements_windows.txt

echo *** Removing pytorch-lightning from requirements_windows
findstr /V "lightning" requirements_windows.txt > requirements_patched.txt
del requirements_windows.txt
ren requirements_patched.txt requirements_windows.txt

echo *** Removing torch from requirements_windows
findstr /V "torch" requirements_windows.txt > requirements_patched.txt
del requirements_windows.txt
ren requirements_patched.txt requirements_windows.txt

echo *** %time% VoC *** Installing requirements
rem python.exe -m pip install --upgrade pip
python -m pip install -U pip
python -m pip install pip==24.2
pip install -r requirements_windows.txt
pip install scipy
pip install pytorch-lightning

rem echo *** VoC - patching xformers
rem pip uninstall -y xformers
rem pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts xformers==0.0.25 --index-url https://download.pytorch.org/whl/cu118

echo *** VoC - Installing GPU torch
pip uninstall -y torch
pip uninstall -y torch
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.1.2+cu118 torchvision==0.16.2 torchaudio --extra-index-url https://download.pytorch.org/whl/cu118

echo *** VoC - Patching transformers
pip uninstall -y transformers
pip install transformers

echo *** VoC - Patching numpy
pip uninstall -y numpy
pip uninstall -y numpy
pip install numpy==1.23.5

echo *** VoC - patching typing_extensions
pip uninstall -y typing_extensions
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts typing_extensions==4.11.0


echo *** %time% VoC *** Downloading models
git lfs install
git clone https://huggingface.co/taocode/anitalker_ckpts ckpts

curl -L -o code/data_preprocess/shape_predictor_68_face_landmarks.dat https://github.com/italojs/facial-landmarks-recognition/raw/master/shape_predictor_68_face_landmarks.dat -v
curl -L -o code/data_preprocess/M003_template.npy https://raw.githubusercontent.com/tanshuai0219/EDTalk/main/data_preprocess/M003_template.npy -v

call venv\scripts\deactivate.bat
cd ..
echo *** %time% VoC *** Finished AniTalker install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause
