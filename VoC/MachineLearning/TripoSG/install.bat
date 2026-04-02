@echo off



echo *** %time% *** Deleting TripoSG directory if it exists
if exist TripoSG\. rd /S /Q TripoSG

echo *** %time% *** Cloning TripoSG repository
git clone --recursive https://github.com/VAST-AI-Research/TripoSG
cd TripoSG

echo *** Creating venv
python -m venv venv
call venv\scripts\activate.bat

echo *** %time% *** Installing requirements
python -m pip install --upgrade pip==24.3.1
pip install wheel
pip install setuptools
rem pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.5.1+cu124 torchvision torchaudio xformers --index-url https://download.pytorch.org/whl/cu124
rem pip install --pre torch torchvision torchaudio --index-url https://download.pytorch.org/whl/nightly/cu128
pip install torch==2.7.0+cu128 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128

pip install -r requirements.txt
pip install jaxtyping
pip install typeguard
pip install triton-windows
pip install hf_xet
pip uninstall -y transforemrs
rem pip install transformers==4.51.0
pip install transformers==4.52.1

cd ..
echo *** %time% VoC *** Finished TripoSG install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause
