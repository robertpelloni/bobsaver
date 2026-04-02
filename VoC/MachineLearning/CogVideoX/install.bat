@echo off



echo *** %time% VoC *** Deleting CogVideo directory if it exists
if exist CogVideo\. rd /S /Q CogVideo

echo *** %time% VoC *** Cloning CogVideo repository
git clone https://github.com/THUDM/CogVideo
cd CogVideo

echo *** %time% VoC *** Creating venv
python -m venv venv

echo *** %time% VoC *** Activating venv
call venv\scripts\activate.bat

echo *** Removing torch from requirements
findstr /V "deepspeed" requirements.txt > requirements_patched.txt
del requirements.txt
ren requirements_patched.txt requirements.txt

echo *** Removing diffusers from requirements
findstr /V "diffusers" requirements.txt > requirements_patched.txt
del requirements.txt
ren requirements_patched.txt requirements.txt

echo *** %time% VoC *** Installing requirements
python.exe -m pip install --upgrade pip
pip install git+https://github.com/huggingface/diffusers.git@89e4d6219805975bd7d253a267e1951badc9f1c0
rem pip install https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/deepspeed-0.12.7+40342055-py3-none-any.whl
pip install deepspeed==0.16.5
pip install -r requirements.txt

echo *** VoC - Installing GPU torch
pip uninstall -y torch
pip uninstall -y torch
rem pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.4.0+cu118 torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/cu118
rem pip install --pre torch torchvision torchaudio --index-url https://download.pytorch.org/whl/nightly/cu128
pip install torch==2.7.0+cu128 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128

echo *** VoC - Patching fsspec
pip uninstall -y fsspec
pip install fsspec==2024.9.0

echo *** VoC - Patching numpy
pip uninstall -y numpy
pip uninstall -y numpy
pip uninstall -y numpy
pip install numpy==1.26.0

echo *** VoC - Patching pillow
pip uninstall -y pillow
pip uninstall -y pillow
pip install pillow==9.5.0

echo *** VoC - patching typing_extensions
pip uninstall -y typing_extensions
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts typing_extensions==4.11.0

call venv\scripts\deactivate.bat
cd ..
echo *** %time% VoC *** Finished CogVideo(X) install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause
