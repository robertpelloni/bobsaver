@echo off



cd
echo *** %time% *** Installing 3090 TRELLIS
echo *** %time% *** Deleting TRELLIS directory if it exists
if exist TRELLIS\. rd /S /Q TRELLIS

echo *** %time% *** Cloning TRELLIS repository
git clone --recurse-submodules https://github.com/microsoft/TRELLIS.git
cd TRELLIS

echo *** %time% *** Creating venv
python -m venv venv
call venv\scripts\activate.bat

echo *** %time% *** Upgrading pip
python -m pip install --upgrade pip==24.3.1

echo *** %time% *** Installing requirements
pip install ninja
pip install torch==2.5.1 torchvision --index-url=https://download.pytorch.org/whl/cu124
pip install xformers==0.0.28.post3 --index-url=https://download.pytorch.org/whl/cu124
pip install pillow imageio imageio-ffmpeg tqdm easydict opencv-python-headless scipy ninja rembg onnxruntime trimesh xatlas pyvista pymeshfix igraph transformers
pip install git+https://github.com/EasternJournalist/utils3d.git@9a4eb15e4021b67b12c460c7057d642626897ec8
pip install https://github.com/bdashore3/flash-attention/releases/download/v2.7.1.post1/flash_attn-2.7.1.post1+cu124torch2.5.1cxx11abiFALSE-cp310-cp310-win_amd64.whl
pip install kaolin -f https://nvidia-kaolin.s3.us-east-2.amazonaws.com/torch-2.5.1_cu124.html

echo *** %time% *** Downloading 3090 wheels
curl -L -o TRELLIS_3090.rar https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/TRELLIS_3090.rar -v

echo *** %time% *** Extracting 3090 wheels
..\7z x TRELLIS_3090.rar

echo *** %time% *** Installing 3090 wheels
pip install nvdiffrast-0.3.3-py3-none-any.whl
pip install diffoctreerast-0.0.0-cp310-cp310-win_amd64.whl
pip install diff_gaussian_rasterization-0.0.0-cp310-cp310-win_amd64.whl
pip install simple_knn-0.0.0-cp310-cp310-win_amd64.whl
pip install vox2seq-0.0.0-cp310-cp310-win_amd64.whl

echo *** %time% *** Installing more requirements
pip install spconv-cu120
pip install gradio==4.44.1 gradio_litmodel3d==0.0.1
pip install triton-windows==3.2.0.post19
pip install open3d

echo *** %time% *** Patching pydantic
pip uninstall -y pydantic
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts pydantic==2.10.6

call venv\scripts\deactivate.bat
cd..

echo *** %time% *** Finished TRELLIS install
echo.
echo *** %time% *** Scroll up and check for errors.  Do not assume it worked.
pause
