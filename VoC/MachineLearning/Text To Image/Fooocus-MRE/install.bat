@echo off
cls
D:
cd "D:\code\delphi\Chaos\Examples\MachineLearning\Text To Image\Fooocus-MRE\"

echo *** VoC - Deleting Fooocus-MRE directory if it exists
if exist Fooocus-MRE\. rd /S /Q Fooocus-MRE
md Fooocus-MRE
cd Fooocus-MRE

echo *** VoC - Downloading Fooocus-MRE-v2.0.78.5.7z
curl -L -o "Fooocus-MRE.zip" "https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/Fooocus-MRE-v2.0.78.5.7z" -v

echo *** VoC - Extracting downloaded zip
..\7z x Fooocus-MRE.zip

echo *** VoC - Deleting downloaded zip
del Fooocus-MRE.zip

echo *** VoC - Fixing read-only attribute of run-mre.bat
attrib -r run-mre.bat

cd..

echo *** VoC - Updating launch.py so torch is not rolled back
echo *** VoC - Current directory
cd
echo *** VoC - BEFORE launch.py deletion
if exist Fooocus-MRE\Fooocus-MRE\launch.py echo *** VoC - Fooocus-MRE\Fooocus-MRE\launch.py EXISTS
if not exist Fooocus-MRE\Fooocus-MRE\launch.py echo *** VoC - Fooocus-MRE\Fooocus-MRE\launch.py DOES NOT EXIST
del Fooocus-MRE\Fooocus-MRE\launch.py
echo *** VoC - AFTER launch.py deletion
if exist Fooocus-MRE\Fooocus-MRE\launch.py echo *** VoC - Fooocus-MRE\Fooocus-MRE\launch.py EXISTS
if not exist Fooocus-MRE\Fooocus-MRE\launch.py echo *** VoC - Fooocus-MRE\Fooocus-MRE\launch.py DOES NOT EXIST
echo *** VoC - Copying launch.py
copy launch.py Fooocus-MRE\Fooocus-MRE\launch.py
echo *** VoC - AFTER launch.py copy
if exist Fooocus-MRE\Fooocus-MRE\launch.py echo *** VoC - Fooocus-MRE\Fooocus-MRE\launch.py EXISTS
if not exist Fooocus-MRE\Fooocus-MRE\launch.py echo *** VoC - Fooocus-MRE\Fooocus-MRE\launch.py DOES NOT EXIST

echo *** VoC - Updating entry_with_update.py so code is not updated 
echo *** VoC - Current directory
cd
echo *** VoC - BEFORE entry_with_update.py deletion
if exist Fooocus-MRE\Fooocus-MRE\entry_with_update.py echo *** VoC - Fooocus-MRE\Fooocus-MRE\entry_with_update.py EXISTS
if not exist Fooocus-MRE\Fooocus-MRE\entry_with_update.py echo *** VoC - Fooocus-MRE\Fooocus-MRE\entry_with_update.py DOES NOT EXIST
del Fooocus-MRE\Fooocus-MRE\entry_with_update.py
echo *** VoC - AFTER entry_with_update.py deletion
if exist Fooocus-MRE\Fooocus-MRE\entry_with_update.py echo *** VoC - Fooocus-MRE\Fooocus-MRE\entry_with_update.py EXISTS
if not exist Fooocus-MRE\Fooocus-MRE\entry_with_update.py echo *** VoC - Fooocus-MRE\Fooocus-MRE\entry_with_update.py DOES NOT EXIST
echo *** VoC - Copying entry_with_update.py
copy entry_with_update.py Fooocus-MRE\Fooocus-MRE\entry_with_update.py
echo *** VoC - AFTER entry_with_update.py copy
if exist Fooocus-MRE\Fooocus-MRE\entry_with_update.py echo *** VoC - Fooocus-MRE\Fooocus-MRE\entry_with_update.py EXISTS
if not exist Fooocus-MRE\Fooocus-MRE\entry_with_update.py echo *** VoC - Fooocus-MRE\Fooocus-MRE\entry_with_update.py DOES NOT EXIST

rem The rest of this is patching Python packages so Fooocus-MRE runs on 50xx GPUs

cd Fooocus-MRE
cd Fooocus-MRE-env

echo *** VoC - Patching xformers
python.exe -m pip uninstall -y xformers
python.exe -m pip uninstall -y xformers
python.exe -m pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts --no-warn-script-location xformers==0.0.30

echo *** VoC - Patching bitsandbytes
python.exe -m pip uninstall -y bitsandbytes
python.exe -m pip uninstall -y bitsandbytes
python.exe -m pip uninstall -y bitsandbytes
python.exe -m pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts --no-warn-script-location bitsandbytes==0.45.5

echo *** VoC - Patching pytorch
python.exe -m pip uninstall -y torch
python.exe -m pip uninstall -y torch
python.exe -m pip uninstall -y torch
python.exe -m pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts --no-warn-script-location torch==2.7.0+cu128 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128

echo *** VoC - Patching transformers
python.exe -m pip uninstall -y transformers
python.exe -m pip uninstall -y transformers
python.exe -m pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts --no-warn-script-location transformers==4.37.0

echo *** VoC - Patching safetensors
python.exe -m pip uninstall -y safetensors
python.exe -m pip uninstall -y safetensors
python.exe -m pip uninstall -y safetensors
python.exe -m pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts --no-warn-script-location safetensors==0.5.3

echo *** VoC - Patching tokenizers
python.exe -m pip uninstall -y tokenizers
python.exe -m pip uninstall -y tokenizers
python.exe -m pip uninstall -y tokenizers
python.exe -m pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts --no-warn-script-location tokenizers==0.21.1

echo *** VoC - Patching numpy
python.exe -m pip uninstall -y numpy
python.exe -m pip uninstall -y numpy
python.exe -m pip uninstall -y numpy
python.exe -m pip uninstall -y numpy
python.exe -m pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts --no-warn-script-location numpy==1.26.4

echo *** VoC - finished Fooocus-MRE install

echo.
echo *** Scroll up and check for any error messages.  Do not assume the install worked. ***
pause
