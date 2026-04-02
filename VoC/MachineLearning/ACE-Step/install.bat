@echo off



if exist ACE-Step\. rd /S /Q ACE-Step

echo *** %time% *** Cloning ACE-Step repository
git clone https://github.com/ace-step/ACE-Step
cd ACE-Step

echo *** Creating venv
python -m venv venv
call venv\scripts\activate.bat

echo *** %time% *** Installing requirements
python -m pip install --upgrade pip==24.3.1
pip install wheel
pip install setuptools
rem pip install -r requirements.txt
pip install -e .
rem pip install git+https://github.com/ace-step/ACE-Step.git
pip install hf_xet

pip uninstall -y torch
pip uninstall -y torch
pip install torch==2.7.0+cu128 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128

echo *** %time% *** Patching gradio
pip uninstall -y gradio
pip install gradio==5.47.2

cd ..
echo *** %time% VoC *** Finished ACE-Step install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause
