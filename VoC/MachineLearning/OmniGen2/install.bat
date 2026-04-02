@echo off



echo *** %time% *** Deleting OmniGen2 directory if it exists
if exist OmniGen2\. rd /S /Q OmniGen2

echo *** %time% *** Cloning DiffSynth-Studio repository
git clone https://github.com/VectorSpaceLab/OmniGen2
cd OmniGen2

echo *** %time% *** Creating venv
python -m venv venv

echo *** %time% *** Activating venv
call venv\scripts\activate.bat

echo *** %time% *** Installing requirements
python -m pip install --upgrade pip
pip install -r requirements.txt
pip install gradio
pip install huggingface_hub[hf_xet]
pip install https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/flash_attn-2.7.4.post1-cp310-cp310-win_amd64.whl
pip install hf_xet

echo *** %time% *** Installing GPU torch
pip uninstall -y torch
pip uninstall -y torch
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.7.0+cu128 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128

pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts triton-windows

call venv\scripts\deactivate.bat
cd ..
echo *** %time% *** Finished OmniGen2 install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause
