@echo off



echo *** %time% *** Deleting magicquill directory if it exists
if exist magicquill\. rd /S /Q magicquill

echo *** %time% *** Cloning genwarp repository
git clone  --recursive https://github.com/magic-quill/magicquill
cd magicquill

echo *** %time% *** Creating venv
python -m venv venv

echo *** %time% *** Activating venv
call venv\scripts\activate.bat

echo *** %time% *** Installing requirements
python -m pip install --upgrade pip==24.3.1
pip install wheel
pip install setuptools
pip install gradio_magicquill-0.0.1-py3-none-any.whl

copy pyproject.toml MagicQuill\LLaVA\pyproject.toml
pip install -e MagicQuill\LLaVA\

pip install -r requirements.txt

pip install https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/triton-3.0.0-cp310-cp310-win_amd64.whl

echo *** %time% *** Patching xformers
pip uninstall -y xformers
rem pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts xformers==0.0.27.post2 --index-url https://download.pytorch.org/whl/cu121
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts xformers==0.0.30

echo *** %time% *** Installing GPU torch
pip uninstall -y torch
pip uninstall -y torch
pip uninstall -y torch
rem pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.4.0+cu121 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.7.0+cu128 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128

echo *** %time% *** Patching typing_extensions
pip uninstall -y typing_extensions
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts typing_extensions==4.11.0

echo *** %time% *** Patching pydantic
pip uninstall -y pydantic
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts pydantic==2.10.6

echo *** %time% *** Downloading models
rd models /s/q
git lfs install
git clone https://huggingface.co/LiuZichen/MagicQuill-models
move MagicQuill-models models

call venv\scripts\deactivate.bat
cd ..
echo *** %time% *** Finished MagicQuill install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause
