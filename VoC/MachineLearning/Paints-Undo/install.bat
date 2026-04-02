@echo off



echo *** %time% VoC *** Deleting Paints-UNDO directory if it exists
if exist Paints-UNDO\. rd /S /Q Paints-UNDO

echo *** %time% VoC *** Cloning Paints-UNDO repository
git clone https://github.com/lllyasviel/Paints-UNDO
cd Paints-UNDO

echo *** %time% VoC *** Creating venv
python -m venv venv

echo *** %time% VoC *** Activating venv
call venv\scripts\activate.bat

echo *** %time% VoC *** Installing requirements
python -m pip install --upgrade pip
pip install -r requirements.txt

echo *** VoC - patching xformers
pip uninstall -y xformers
rem pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts xformers==0.0.27 --index-url https://download.pytorch.org/whl/cu118
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts xformers==0.0.30

echo *** VoC - patching other packages
pip uninstall -y charset-normalizer
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts charset-normalizer==3.3.2
pip uninstall -y pydantic
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts pydantic==2.10.6
pip uninstall -y accelerate
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts accelerate==1.10.1

echo *** VoC - installing GPU torch
pip uninstall -y torch
pip uninstall -y torch
rem pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.3.0+cu118 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.7.0+cu128 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128

echo *** VoC - patching other packages
pip uninstall -y transformers
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts transformers==4.37.2
pip uninstall -y huggingface-hub
pip uninstall -y huggingface-hub
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts huggingface-hub==0.25.0
pip install hf_xet

cd ..
echo *** %time% VoC *** Finished Paints-UNDO install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause
