@echo off



echo *** %time% VoC *** Deleting higgs_audio_v2 directory if it exists
if exist higgs_audio_v2\. rd /S /Q higgs_audio_v2

echo *** %time% VoC *** Cloning repository
git clone https://huggingface.co/spaces/smola/higgs_audio_v2
cd higgs_audio_v2

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
echo *** %time% VoC *** Finished Higgs Audio v2 install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause
