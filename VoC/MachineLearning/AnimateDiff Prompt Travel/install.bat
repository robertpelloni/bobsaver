@echo off
cls
 
 


echo *** %time% *** Deleting animatediff-cli-prompt-travel directory if it exists
if exist animatediff-cli-prompt-travel\. rd /S /Q animatediff-cli-prompt-travel

echo *** %time% *** Cloning repository
git clone https://github.com/s9roll7/animatediff-cli-prompt-travel --recursive

rem get working commit
rem cd animatediff-cli-prompt-travel
rem this commit hash needs to match the one in voc_animatediffprompt.txt
rem git reset --hard 7d630185280193e1c6493f255f627d8b10a5b2ab
rem cd..

del animatediff-cli-prompt-travel\data\controlnet_image\test\*.* /s /q > nul

copy animatediff-cli-prompt-travel\config\prompts\prompt_travel.json prompt_travel.json

echo *** %time% *** Creating venv

cd animatediff-cli-prompt-travel
python -m venv venv
call venv\Scripts\activate.bat

echo *** %time% *** Upgrading pip

set PYTHONUTF8=1
python.exe -m pip install --upgrade pip

echo *** %time% *** Installing torch as pre-req for animatediff build and install
pip install torch==2.1.0+cu121 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121

echo *** %time% *** Installing xformers as pre-req for animatediff build and install
pip install xformers==0.0.22.post7

echo *** %time% *** Installing animatediff
pip install -e .

echo *** %time% *** Installing [stylize]
rem If you want to use the 'stylize' command, you will also need
pip install -e .[stylize]

echo *** %time% *** Installing [dwpose]
rem If you want to use use dwpose as a preprocessor for controlnet_openpose, you will also need
pip install -e .[dwpose]

echo *** %time% *** Installing [stylize_mask]
rem If you want to use the 'stylize create-mask' and 'stylize composite' command, you will also need
pip install -e .[stylize_mask]

echo *** %time% *** Patching huggingface_hub
pip uninstall -y huggingface_hub
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts huggingface_hub==0.22.2

echo *** %time% *** Patching mediapipe
pip uninstall -y mediapipe
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts mediapipe==0.10.5

echo *** %time% *** Installing GPU support
pip uninstall -y xformers
rem pip uninstall -y xformers
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts xformers==0.0.30
rem pip uninstall -y torch
pip uninstall -y torch
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.7.0+cu128 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128
pip install triton-windows

call venv\Scripts\activate.bat

echo.
echo *** VoC - finished AnimateDiff Prompt Travel install

echo.
echo *** Scroll up and check for any error messages.  Do not assume the install worked. ***
pause