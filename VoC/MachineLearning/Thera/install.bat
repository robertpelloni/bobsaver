@echo off



echo *** %time% *** Deleting Thera directory if it exists
if exist Thera\. rd /S /Q Thera

echo *** %time% *** Cloning Thera repository
git clone https://github.com/prs-eth/thera
ren thera Thera
cd Thera

echo *** %time% *** Cloning Thera Gradio repository
git clone https://huggingface.co/spaces/prs-eth/thera thera-demo

echo *** Creating venv
python -m venv venv
call venv\scripts\activate.bat

echo *** %time% *** Stripping jax from requirements.txt
type requirements.txt | findstr /v jax > stripped.txt
del requirements.txt
ren stripped.txt requirements.txt

echo *** %time% *** Stripping nvidia from requirements.txt
type requirements.txt | findstr /v nvidia > stripped.txt
del requirements.txt
ren stripped.txt requirements.txt

echo *** %time% *** Installing requirements
python -m pip install --upgrade pip==24.3.1
pip install -r requirements.txt
pip install jaxlib
pip install jaxtyping
pip install gradio_imageslider==0.0.20
pip install spaces
pip install gradio==4.44.1

echo *** %time% - Installing GPU torch
pip uninstall -y torch
pip uninstall -y torch
rem pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.5.1+cu124 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124
pip install torch==2.7.0+cu128 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128

echo *** %time% - Patching numpy
pip uninstall -y numpy
pip uninstall -y numpy
pip install numpy==1.26.4

echo *** %time% - Patching pydantic
pip uninstall -y pydantic
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts pydantic==2.10.6

echo *** %time% - Downloading models

md models
curl -L -o ./models/thera-edsr-air.pkl https://huggingface.co/prs-eth/thera-edsr-air/resolve/main/model.pkl -v
curl -L -o ./models/thera-edsr-plus.pkl https://huggingface.co/prs-eth/thera-edsr-plus/resolve/main/model.pkl -v
curl -L -o ./models/thera-edsr-pro.pkl https://huggingface.co/prs-eth/thera-edsr-pro/resolve/main/model.pkl -v
curl -L -o ./models/thera-rdn-air.pkl https://huggingface.co/prs-eth/thera-rdn-air/resolve/main/model.pkl -v
curl -L -o ./models/thera-rdn-plus.pkl https://huggingface.co/prs-eth/thera-rdn-plus/resolve/main/model.pkl -v
curl -L -o ./models/thera-rdn-pro.pkl https://huggingface.co/prs-eth/thera-rdn-pro/resolve/main/model.pkl -v

cd ..
echo *** %time% VoC *** Finished Thera install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause
