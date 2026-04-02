@echo off



cd
echo *** Deleting Qwen2.5-Omni directory if it exists
if exist Qwen2.5-Omni\. rd /S /Q Qwen2.5-Omni

echo *** Cloning Qwen2.5-Omni repository
git lfs install
git clone https://github.com/QwenLM/Qwen2.5-Omni
cd Qwen2.5-Omni

echo *** Creating venv
python -m venv venv
call venv\scripts\activate.bat

echo *** Upgrading pip
python -m pip install --upgrade pip==24.3.1

echo *** Installing requirements
pip install -r requirements_web_demo.txt
pip uninstall -y flash-attn
rem pip install https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/flash_attn-2.7.4+cu121torch2.5.0cxx11abiFALSE-cp310-cp310-win_amd64.whl
pip install https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/flash_attn-2.7.4.post1-cp310-cp310-win_amd64.whl
pip install triton-windows

echo Patching gradio
pip uninstall -y gradio
pip install gradio==5.23.1

echo *** Installing GPU Torch
pip uninstall -y torch
pip uninstall -y torch
rem pip install torch==2.5.1+cu124 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.7.0+cu128 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128

pip uninstall -y pydantic
pip uninstall -y pydantic
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts pydantic==2.11.0


call venv\scripts\deactivate.bat
cd..

echo *** Finished Qwen2.5-Omni install
echo.
echo *** Scroll up and check for errors.  Do not assume it worked.
pause
