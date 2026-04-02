@echo off



if exist MIDI-3D\. rd /S /Q MIDI-3D

echo *** %time% VoC *** Cloning MIDI-3D repository
git clone https://github.com/VAST-AI-Research/MIDI-3D
cd MIDI-3D

echo *** %time% VoC *** Creating venv
python -m venv venv
call venv\scripts\activate.bat

echo *** %time% VoC *** Patching requirements
findstr /V "cluster" requirements.txt > requirements_patched.txt
del requirements.txt
ren requirements_patched.txt requirements.txt

echo *** %time% VoC *** Installing requirements
python -m pip install --upgrade pip==24.3.1
pip install -r requirements.txt
pip install https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/torch_cluster-1.6.3+pt25cu124-cp310-cp310-win_amd64.whl

echo *** %time% VoC *** Installing GPU torch
pip uninstall -y torch
pip uninstall -y torch
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.5.1+cu124 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124
rem pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.7.0+cu128 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128

echo *** %time% VoC *** Patching numpy
pip uninstall -y numpy
pip uninstall -y numpy
pip install numpy==1.26.4

cd ..
echo *** %time% VoC *** Finished MIDI-3D install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause
