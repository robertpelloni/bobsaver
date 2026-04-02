@echo off



echo *** %time% *** Deleting InvSR directory if it exists
if exist InvSR\. rd /S /Q InvSR

echo *** %time% *** Cloning InvSR repository
git clone https://github.com/zsyOAOA/InvSR
cd InvSR

echo *** %time% *** Creating venv
python -m venv venv

echo *** %time% *** Activating venv
call venv\scripts\activate.bat

echo *** %time% *** Installing requirements
python -m pip install --upgrade pip==24.3.1
rem pip install torch==2.4.0 torchvision==0.19.0 torchaudio==2.4.0 --index-url https://download.pytorch.org/whl/cu121
rem pip install -U xformers==0.0.27.post2 --index-url https://download.pytorch.org/whl/cu121

rem pip install https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/xformers-0.0.30+836cd905.d20250327-cp310-cp310-win_amd64.whl
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts xformers==0.0.30
pip install torch==2.7.0+cu128 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts triton-windows==3.5.0.post21

pip install -e ".[torch]"
pip install -r requirements.txt

rem echo *** %time% *** Patching typing_extensions
rem pip uninstall -y typing_extensions
rem pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts typing_extensions==4.11.0

echo *** %time% *** Patching numpy
pip uninstall -y numpy
pip install numpy==1.26.4

echo *** %time% *** Patching pydantic
pip uninstall -y pydantic
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts pydantic==2.10.6

cd..
call venv\scripts\deactivate.bat

echo *** %time% *** Finished InvSR install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause
