@echo off



echo *** %time% VoC *** Deleting ObjectClear directory if it exists
if exist ObjectClear\. rd /S /Q ObjectClear

echo *** %time% VoC *** Cloning repository
git clone https://huggingface.co/spaces/jixin0101/ObjectClear
cd ObjectClear

echo *** Creating venv
python -m venv venv
call venv\scripts\activate.bat

echo *** %time% *** Installing requirements
python -m pip install --upgrade pip
pip install -r requirements.txt
pip install gradio
pip install spaces

echo *** VoC - Installing GPU torch
pip uninstall -y torch
pip uninstall -y torch
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.7.0+cu128 torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/cu128

cd ..
echo *** %time% VoC *** Finished ObjectClear install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause
