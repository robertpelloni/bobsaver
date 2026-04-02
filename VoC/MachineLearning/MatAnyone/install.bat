@echo off



if exist MatAnyone\. rd /S /Q MatAnyone

echo *** %time% VoC *** Cloning MatAnyone repository
git clone https://github.com/pq-yang/MatAnyone
cd MatAnyone

echo *** %time% VoC *** Creating venv
python -m venv venv
call venv\scripts\activate.bat

echo *** %time% VoC *** Installing requirements
python -m pip install --upgrade pip==24.3.1
pip install -e .
pip install -r hugging_face\requirements.txt

echo *** %time% VoC *** Installing GPU torch
pip uninstall -y torch
pip uninstall -y torch
rem pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.5.1+cu124 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.7.0+cu128 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128

echo *** %time% VoC *** Patching numpy
pip uninstall -y numpy
pip uninstall -y numpy
pip install numpy==1.26.4

echo *** %time% VoC *** Downloading models
md pretrained_models
curl -L -o pretrained_models\matanyone.pth https://github.com/pq-yang/MatAnyone/releases/download/v1.0.0/matanyone.pth -v

cd ..
echo *** %time% VoC *** Finished MatAnyone install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause
