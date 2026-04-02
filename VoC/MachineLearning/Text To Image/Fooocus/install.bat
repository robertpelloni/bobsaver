@echo off
cls
D:
cd "D:\code\Delphi\Chaos\Examples\MachineLearning\Text To Image\Fooocus\"

echo *** VoC - Attempting to download Fooocus_win64_2-5-0.7z
curl -L -o "Fooocus.zip" "https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/Fooocus_win64_2-5-0.7z" -v

echo *** VoC - Deleting Fooocus directory if it exists
if exist Fooocus\. rd /S /Q Fooocus

echo *** VoC - Extracting downloaded zip
7z x Fooocus.zip
move Fooocus_win64_2-5-0 Fooocus

echo *** VoC - Deleting downloaded zip
del Fooocus.zip

echo *** VoC - Updating launch.py so torch is not rolled back
echo *** VoC - Current directory
cd
echo *** VoC - BEFORE launch.py deletion
if exist Fooocus\Fooocus\launch.py echo *** VoC - Fooocus\Fooocus\launch.py EXISTS
if not exist Fooocus\Fooocus\launch.py echo *** VoC - Fooocus\Fooocus\launch.py DOES NOT EXIST
del Fooocus\Fooocus\launch.py
echo *** VoC - AFTER launch.py deletion
if exist Fooocus\Fooocus\launch.py echo *** VoC - Fooocus\Fooocus\launch.py EXISTS
if not exist Fooocus\Fooocus\launch.py echo *** VoC - Fooocus\Fooocus\launch.py DOES NOT EXIST
echo *** VoC - Copying launch.py
copy launch.py Fooocus\Fooocus\launch.py
echo *** VoC - AFTER launch.py copy
if exist Fooocus\Fooocus\launch.py echo *** VoC - Fooocus\Fooocus\launch.py EXISTS
if not exist Fooocus\Fooocus\launch.py echo *** VoC - Fooocus\Fooocus\launch.py DOES NOT EXIST

echo *** VoC - Updating entry_with_update.py so code is not updated 
echo *** VoC - Current directory
cd
echo *** VoC - BEFORE entry_with_update.py deletion
if exist Fooocus\Fooocus\entry_with_update.py echo *** VoC - Fooocus\Fooocus\entry_with_update.py EXISTS
if not exist Fooocus\Fooocus\entry_with_update.py echo *** VoC - Fooocus\Fooocus\entry_with_update.py DOES NOT EXIST
del Fooocus\Fooocus\entry_with_update.py
echo *** VoC - AFTER entry_with_update.py deletion
if exist Fooocus\Fooocus\entry_with_update.py echo *** VoC - Fooocus\Fooocus\entry_with_update.py EXISTS
if not exist Fooocus\Fooocus\entry_with_update.py echo *** VoC - Fooocus\Fooocus\entry_with_update.py DOES NOT EXIST
echo *** VoC - Copying entry_with_update.py
copy entry_with_update.py Fooocus\Fooocus\entry_with_update.py
echo *** VoC - AFTER entry_with_update.py copy
if exist Fooocus\Fooocus\entry_with_update.py echo *** VoC - Fooocus\Fooocus\entry_with_update.py EXISTS
if not exist Fooocus\Fooocus\entry_with_update.py echo *** VoC - Fooocus\Fooocus\entry_with_update.py DOES NOT EXIST

echo *** VoC - Patching pytorch
cd Fooocus
cd python_embeded
python.exe -m pip install typing-extensions==4.10.0
python.exe -m pip install Jinja2==3.1.4
python.exe -m pip uninstall -y torch
python.exe -m pip uninstall -y torch
python.exe -m pip install torch==2.7.0+cu128 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128

echo *** VoC - Patching numpy
python.exe -m pip uninstall -y numpy
python.exe -m pip uninstall -y numpy
python.exe -m pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts --no-warn-script-location numpy==1.26.4

echo *** VoC - finished Fooocus install

echo.
echo *** Scroll up and check for any error messages.  Do not assume the install worked. ***
pause

