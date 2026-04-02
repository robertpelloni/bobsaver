@echo off



cd
echo *** Deleting PuLID directory if it exists
if exist PuLID\. rd /S /Q PuLID

echo *** Cloning PuLID repository
git clone https://github.com/ToTheBeginning/PuLID
cd PuLID

echo *** Creating venv
python -m venv venv
call venv\scripts\activate.bat

echo *** Upgrading pip
python -m pip install --upgrade pip==24.3.1
rem pip install pip==23.0.1

rem echo *** Patching requirements
rem findstr /V "nerfacc" requirements.txt > requirements_patched.txt
rem del requirements.txt
rem ren requirements_patched.txt requirements.txt

echo *** Installing requirements
pip install -r requirements.txt
pip install -r requirements_fp8.txt
pip install https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/triton-3.0.0-cp310-cp310-win_amd64.whl

echo *** Patching gradio
pip uninstall -y gradio
pip install gradio==4.43.0
rem pip install basicsr==1.4.2
pip uninstall -y pydantic
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts pydantic==2.10.6
pip install hf_xet

rem echo *** Installing xformers
rem pip uninstall -y xformers
rem pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts xformers==0.0.27 --index-url https://download.pytorch.org/whl/cu121
rem pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts xformers==0.0.30

echo *** Installing GPU torch
pip uninstall -y torch
pip uninstall -y torch
rem pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.3.1+cu121 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121
rem pip install --pre torch torchvision torchaudio --index-url https://download.pytorch.org/whl/nightly/cu128
pip install torch==2.7.0+cu128 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128

echo *** Patching typing_extensions
pip uninstall -y typing_extensions
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts typing_extensions==4.11.0

call venv\scripts\deactivate.bat
cd..

echo *** Finished PuLID install
echo.
echo *** Scroll up and check for errors.  Do not assume it worked.
pause

