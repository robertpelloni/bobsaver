@echo off



echo *** %time% VoC *** Deleting HunyuanVideoGP directory if it exists
if exist HunyuanVideoGP\. rd /S /Q HunyuanVideoGP

echo *** %time% VoC *** Cloning HunyuanVideoGP repository
git clone https://github.com/deepbeepmeep/HunyuanVideoGP
cd HunyuanVideoGP

echo *** Creating venv
python -m venv venv
call venv\scripts\activate.bat

echo *** %time% *** Installing requirements
python -m pip install --upgrade pip==24.3.1
pip install -r requirements.txt
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts xformers==0.0.30
pip install https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/sageattention-2.1.1+cu128torch2.7.0-cp310-cp310-win_amd64.whl
pip install https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/flash_attn-2.7.4.post1-cp310-cp310-win_amd64.whl
pip install hf_xet

echo *** VoC - Installing GPU torch
pip uninstall -y torch
pip uninstall -y torch
pip install torch==2.7.0+cu128 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128

echo *** VoC - Patching numpy
pip uninstall -y numpy
pip uninstall -y numpy
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts numpy==1.26.4

cd ..
echo *** %time% VoC *** Finished HunyuanVideoGP install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause
