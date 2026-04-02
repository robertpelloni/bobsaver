@echo off



cd
echo *** Deleting Qwen2.5-VL directory if it exists
if exist Qwen2.5-VL\. rd /S /Q Qwen2.5-VL

echo *** Cloning Qwen2.5-VL repository
git lfs install
git clone https://github.com/QwenLM/Qwen2.5-VL
cd Qwen2.5-VL

echo *** Creating venv
python -m venv venv
call venv\scripts\activate.bat

echo *** Upgrading pip
python -m pip install --upgrade pip==24.3.1

echo *** Installing requirements
pip install -r requirements_web_demo.txt

rem echo Patching gradio
rem pip uninstall -y gradio
rem pip uninstall -y gradio_client
rem pip install gradio==5.4.0
rem pip install gradio_client==1.4.2

echo *** Installing GPU Torch
pip uninstall -y torch
pip uninstall -y torch
rem pip install torch==2.5.1+cu124 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.7.0+cu128 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128

pip uninstall -y pydantic
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts pydantic==2.10.6

call venv\scripts\deactivate.bat
cd..

echo *** Finished Qwen2.5-VL install
echo.
echo *** Scroll up and check for errors.  Do not assume it worked.
pause
