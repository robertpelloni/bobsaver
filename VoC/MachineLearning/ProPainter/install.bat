cls
@echo off
D:
cd "D:\code\delphi\Chaos\Examples\MachineLearning\ProPainter\"

echo *** VoC - Deleting ProPainter-Webui directory if it exists
if exist ProPainter-Webui\. rd /S /Q ProPainter-Webui

echo *** VoC - cloning ProPainter-Webui
git clone https://github.com/Katehuuh/ProPainter-Webui.git
cd ProPainter-Webui

echo *** VoC - setting up Python environment
python -m venv venv

echo *** VoC - activating up Python environment
call venv\Scripts\activate.bat

echo *** VoC - updating pip
python -m pip install --upgrade pip==24.3.1

echo *** VoC - installing requirements
pip3 install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
pip3 install -r ProPainter\requirements.txt
pip3 install -e ./sam
pip install -r requirements.txt

echo *** VoC - cloning Pytorch-Correlation-extension
git clone https://github.com/ClementPinard/Pytorch-Correlation-extension.git
cd Pytorch-Correlation-extension

echo *** VoC - installing Pytorch-Correlation-extension
python setup.py install
cd ..

echo *** VoC - patching typing_extensions
pip uninstall -y typing_extensions
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts typing_extensions==4.11.0

echo *** VoC - downloading required models
mkdir ckpt
curl -L -o ckpt\R50_DeAOTL_PRE_YTB_DAV.pth https://huggingface.co/Nekochu/Models/resolve/main/segment-and-track-anything/ckpt/R50_DeAOTL_PRE_YTB_DAV.pth -v
curl -L -o ckpt\groundingdino_swint_ogc.pth https://huggingface.co/Nekochu/Models/resolve/main/segment-and-track-anything/ckpt/groundingdino_swint_ogc.pth -v
curl -L -o ckpt\sam_vit_b_01ec64.pth https://huggingface.co/Nekochu/Models/resolve/main/segment-and-track-anything/ckpt/sam_vit_b_01ec64.pth -v
git clone https://huggingface.co/bert-base-uncased ckpt/bert-base-uncased

echo *** VoC - install finished
rem python app.py

echo.
echo *** Scroll up and check for any error messages.  Do not assume the install worked. ***
pause
