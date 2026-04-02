@echo off



echo *** %time% *** Deleting DiffSensei directory if it exists
if exist DiffSensei\. rd /S /Q DiffSensei

echo *** %time% *** Cloning DiffSensei repository
git clone https://github.com/jianzongwu/DiffSensei
cd DiffSensei

echo *** %time% *** Creating venv
python -m venv venv

echo *** %time% *** Activating venv
call venv\scripts\activate.bat

echo *** %time% *** Installing requirements
python -m pip install --upgrade pip==24.3.1
rem pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.4.0+cu121 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts xformers==0.0.30
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.7.0+cu128 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128
pip install diffusers transformers accelerate
pip install -U xformers --index-url https://download.pytorch.org/whl/cu121
pip install -r requirements.txt
pip install gradio-image-prompter

echo *** %time% *** Patching typing_extensions
pip uninstall -y typing_extensions
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts typing_extensions==4.11.0

echo *** %time% *** Patching pydantic
pip uninstall -y pydantic
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts pydantic==2.10.6

echo *** %time% *** Downloading models
md checkpoints
cd checkpoints
git lfs install
git clone https://huggingface.co/jianzongwu/DiffSensei

cd..
call venv\scripts\deactivate.bat
cd ..
echo *** %time% *** Finished DiffSensei install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause
