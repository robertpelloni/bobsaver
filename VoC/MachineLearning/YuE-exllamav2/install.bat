@echo off



echo *** %time% *** Deleting YuE-exllamav2 directory if it exists
if exist YuE-exllamav2\. rd /S /Q YuE-exllamav2

echo *** %time% *** Cloning repository
git lfs install
git clone https://github.com/sgsdxzy/YuE-exllamav2.git
cd YuE-exllamav2
git clone https://huggingface.co/m-a-p/xcodec_mini_infer

echo *** Creating venv
python -m venv venv
call venv\scripts\activate.bat

echo *** %time% *** Removing triton from requirements.txt
type requirements.txt | findstr /v triton > stripped.txt
del requirements.txt
ren stripped.txt requirements.txt

echo *** %time% *** Removing flash from requirements.txt
type requirements.txt | findstr /v flash > stripped.txt
del requirements.txt
ren stripped.txt requirements.txt

echo *** %time% *** Installing requirements
python -m pip install --upgrade pip==24.3.1
pip install wheel
pip install setuptools
pip install packaging
rem pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.6.0+cu124 torchvision torchaudio xformers --index-url https://download.pytorch.org/whl/cu124
rem pip install torch==2.7.0+cu128 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128
pip install -r requirements.txt
pip uninstall -y xformers
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts xformers==0.0.30
pip install hf_xet
pip install https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/flash_attn-2.7.4.post1-cp310-cp310-win_amd64.whl

echo *** %time% - Installing GPU torch
pip uninstall -y torch
pip uninstall -y torch
pip uninstall -y torch
rem xformers can be installed with torch
rem pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.6.0+cu124 torchvision torchaudio xformers --index-url https://download.pytorch.org/whl/cu124
pip install torch==2.7.0+cu128 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128
pip install triton-windows

echo *** %time% - Patching numpy
pip uninstall -y numpy
pip uninstall -y numpy
pip install numpy==1.26.4

echo *** %time% - Downloading models
md m-a-p
cd m-a-p
git clone https://huggingface.co/m-a-p/YuE-s1-7B-anneal-en-cot
git clone https://huggingface.co/m-a-p/YuE-s2-1B-general
cd..

cd ..
echo *** %time% VoC *** Finished YuE-exllamav2 install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause
