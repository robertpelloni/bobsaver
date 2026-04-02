@echo off



if exist DreamO\. rd /S /Q DreamO

echo *** %time% *** Cloning DreamO repository
git clone https://github.com/bytedance/DreamO
cd DreamO

echo *** Creating venv
python -m venv venv
call venv\scripts\activate.bat

echo *** %time% *** Installing requirements
python -m pip install --upgrade pip==24.3.1
pip install wheel
pip install setuptools
pip install -r requirements.txt
pip install protobuf

pip uninstall -y torch
pip uninstall -y torch
pip install torch==2.7.0+cu128 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128

pip uninstall -y pydantic
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts pydantic==2.10.6

cd ..
echo *** %time% VoC *** Finished DreamO install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause
