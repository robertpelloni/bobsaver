@echo off



echo *** %time% *** Deleting Hunyuan3D-2.1 directory if it exists
if exist Hunyuan3D-2.1\. rd /S /Q Hunyuan3D-2.1

echo *** %time% *** Cloning Hunyuan3D-2.1 repository
git clone https://github.com/Deathdadev/Hunyuan3D-2.1
cd Hunyuan3D-2.1

echo *** %time% *** Creating venv
python -m venv venv

echo *** %time% *** Activating venv
call venv\scripts\activate.bat

rem remove the redirects as they are too slow and not needed
echo *** Removing extra-index-url from requirements.txt
type requirements.txt | findstr /v extra-index-url > stripped.txt
del requirements.txt
ren stripped.txt requirements.txt

rem remove Trasformers as the version within requirements.txt stops hy3dgen installing
echo *** Removing transformers from requirements.txt
type requirements.txt | findstr /v transformers > stripped.txt
del requirements.txt
ren stripped.txt requirements.txt

echo *** %time% *** Upgrading pip
rem python.exe -m pip install --upgrade pip
python -m pip install -U pip
python -m pip install pip==24.0
pip install wheel==0.45.1
pip install setuptools==65.5.0
pip install ninja==1.11.1.4

echo *** %time% *** Installing requirements
rem need this version of deepspeed as the unversioned deepspeed install within requirements.txt gives a ModuleNotFoundError: No module named 'cpuinfo' and pip install cpuinfo does not work
pip install https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/deepspeed-0.16.3-cp310-cp310-win_amd64.whl
pip install hy3dgen==2.0.2
pip install -r requirements.txt

echo *** %time% *** Installing sentencepiece
pip install sentencepiece==0.2.0

rem install transformers here after hy3dgen to stop conflict errors
echo *** %time% *** Installing transformers
pip install transformers

echo *** %time% *** Installing custom_rasterizer
pip install https://github.com/Deathdadev/Hunyuan3D-2.1/releases/download/windows-whl/custom_rasterizer-0.1-cp310-cp310-win_amd64.whl

echo *** %time% *** Installing DifferentiableRenderer
pip install https://github.com/Deathdadev/Hunyuan3D-2.1/releases/download/windows-whl/mesh_inpaint_processor-0.0.0-cp310-cp310-win_amd64.whl

echo *** %time% *** Installing GPU torch
pip uninstall -y torch
pip uninstall -y torch
pip uninstall -y torch
pip install torch==2.7.0+cu128 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128

echo *** %time% *** Downloading model
md hy3dpaint\ckpt
curl -L -o "hy3dpaint\ckpt\RealESRGAN_x4plus.pth" "https://github.com/xinntao/Real-ESRGAN/releases/download/v0.1.0/RealESRGAN_x4plus.pth" -v

echo *** %time% *** Downloading mesh_inpaint_processor.pyd
curl -L -o "hy3dpaint\DifferentiableRenderer\mesh_inpaint_processor.pyd" "https://github.com/Deathdadev/Hunyuan3D-2.1/releases/download/test/mesh_inpaint_processor.cp310-win_amd64.pyd" -v

call venv\scripts\deactivate.bat
cd ..
echo *** %time% *** Finished Hunyuan3D-2.1 install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause
