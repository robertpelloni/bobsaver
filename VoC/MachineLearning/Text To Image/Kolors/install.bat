@echo off



echo *** %time% *** Deleting Kolors directory if it exists
if exist Kolors\. rd /S /Q Kolors

echo *** %time% *** Cloning Kolors repository
git clone https://github.com/Kwai-Kolors/Kolors
cd Kolors

echo *** %time% *** Removing triton from requirements.txt
type requirements.txt | findstr /v triton > stripped.txt
del requirements.txt
ren stripped.txt requirements.txt

echo *** %time% *** Removing deepspeed from requirements.txt
type requirements.txt | findstr /v deepspeed > stripped.txt
del requirements.txt
ren stripped.txt requirements.txt

echo *** %time% *** Removing safetensors from requirements.txt
type requirements.txt | findstr /v safetensors > stripped.txt
del requirements.txt
ren stripped.txt requirements.txt

echo *** %time% *** Removing transformers from requirements.txt
type requirements.txt | findstr /v transformers > stripped.txt
del requirements.txt
ren stripped.txt requirements.txt

echo *** %time% *** Creating venv
python -m venv venv

echo *** %time% *** Activating venv
call venv\scripts\activate.bat

echo *** %time% *** Installing requirements
python -m pip install --upgrade pip==24.3.1

echo *** %time% *** Installing deepspeed
pip install https://softology.pro/wheels/deepspeed-0.12.7+40342055-py3-none-any.whl

echo *** %time% *** Installing requirements
pip install -r requirements.txt

echo *** %time% *** Installing safetensors
pip install safetensors

echo *** %time% *** Installing transformers
pip install transformers==4.43.0

echo *** %time% *** Installing color_matcher
pip install color_matcher

echo *** %time% *** Installing diffusers
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts git+https://github.com/huggingface/diffusers.git@98930ee131b996c65cbbf48d8af363a98b21492c

echo *** %time% *** Patching xformers
pip uninstall -y xformers
rem pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts xformers==0.0.27.post2 --index-url https://download.pytorch.org/whl/cu121
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts xformers==0.0.30

echo *** %time% *** Installing GPU torch
pip uninstall -y torch
pip uninstall -y torch
rem pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.4.0+cu121 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121
pip install torch==2.7.0+cu128 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128

echo *** %time% *** Installing Kolors
python setup.py install

echo *** %time% *** Installing scipy
pip install scipy==1.10.0

echo *** VoC - patching typing_extensions
pip uninstall -y typing_extensions
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts typing_extensions==4.11.0

echo *** VoC - patching gradio
pip uninstall -y gradio
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts gradio==4.43.0

echo *** %time% *** Patching numpy
pip uninstall -y numpy
pip uninstall -y numpy
pip uninstall -y numpy
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts numpy==1.26.4

echo *** VoC - patching pydantic
pip uninstall -y pydantic
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts pydantic==2.10.6

echo *** %time% *** Downloading models
huggingface-cli download --resume-download Kwai-Kolors/Kolors --local-dir weights/Kolors

call venv\scripts\deactivate.bat
cd ..
echo *** %time% *** Finished Kolors install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause
