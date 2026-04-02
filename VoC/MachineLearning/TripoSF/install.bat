@echo off



echo *** %time% *** Deleting TripoSF directory if it exists
if exist TripoSF\. rd /S /Q TripoSF

echo *** %time% *** Cloning TripoSF repository
git clone https://github.com/VAST-AI-Research/TripoSF
cd TripoSF

echo *** Creating venv
python -m venv venv
call venv\scripts\activate.bat

echo *** %time% *** Installing requirements
python -m pip install --upgrade pip==24.3.1
pip install wheel
pip install ninja
pip install setuptools

pip install torch==2.7.0+cu128 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128
pip install packaging
pip install spconv-cu120
pip install gradio

echo *** Removing flash-attn from requirements
findstr /V "flash-attn" requirements.txt > requirements_patched.txt
del requirements.txt
ren requirements_patched.txt requirements.txt

echo *** Removing spconv from requirements
findstr /V "spconv" requirements.txt > requirements_patched.txt
del requirements.txt
ren requirements_patched.txt requirements.txt

echo *** Removing numpy from requirements
findstr /V "numpy" requirements.txt > requirements_patched.txt
del requirements.txt
ren requirements_patched.txt requirements.txt

echo *** Removing torch-scatter from requirements
findstr /V "scatter" requirements.txt > requirements_patched.txt
del requirements.txt
ren requirements_patched.txt requirements.txt

echo *** %time% *** Installing requirements
pip install -r requirements.txt

echo *** %time% *** Installing flash-attn
pip install https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/flash_attn-2.7.4.post1-cp310-cp310-win_amd64.whl

echo *** %time% *** Installing GPU torch
pip uninstall -y torch
pip uninstall -y torch
pip uninstall -y torch
pip install torch==2.7.0+cu128 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128

echo *** %time% *** Installing torch-scatter
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch-scatter==2.1.2

echo *** %time% *** Patching numpy
pip uninstall -y numpy
pip uninstall -y numpy
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts numpy==1.22.4

echo *** %time% *** Downloading model
md ckpts
curl -L -o "ckpts\pretrained_TripoSFVAE_256i1024o.safetensors" "https://huggingface.co/VAST-AI/TripoSF/resolve/main/vae/pretrained_TripoSFVAE_256i1024o.safetensors" -v

cd ..
echo *** %time% *** Finished TripoSF install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause
