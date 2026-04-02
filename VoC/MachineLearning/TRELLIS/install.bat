@echo off



cd
echo *** Deleting TRELLIS directory if it exists
if exist TRELLIS\. rd /S /Q TRELLIS

echo *** Cloning TRELLIS repository
git clone --recurse-submodules https://github.com/microsoft/TRELLIS.git
cd TRELLIS

echo *** Creating venv
python -m venv venv
call venv\scripts\activate.bat

echo *** Upgrading pip
python -m pip install --upgrade pip==24.3.1

echo *** Installing requirements
pip install torch==2.5.1 torchvision --index-url=https://download.pytorch.org/whl/cu124
pip install xformers==0.0.28.post3 --index-url=https://download.pytorch.org/whl/cu124
pip install pillow imageio imageio-ffmpeg tqdm easydict opencv-python-headless scipy ninja rembg onnxruntime trimesh xatlas pyvista pymeshfix igraph transformers
pip install git+https://github.com/EasternJournalist/utils3d.git@9a4eb15e4021b67b12c460c7057d642626897ec8
pip install https://github.com/bdashore3/flash-attention/releases/download/v2.7.1.post1/flash_attn-2.7.1.post1+cu124torch2.5.1cxx11abiFALSE-cp310-cp310-win_amd64.whl
pip install kaolin -f https://nvidia-kaolin.s3.us-east-2.amazonaws.com/torch-2.5.1_cu124.html
pip install https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/nvdiffrast-0.3.3-py3-none-any.whl
pip install https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/diffoctreerast-0.0.0-cp310-cp310-win_amd64.whl
pip install https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/diff_gaussian_rasterization-0.0.0-cp310-cp310-win_amd64.whl
pip install https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/vox2seq-0.0.0-cp310-cp310-win_amd64.whl
pip install spconv-cu120
pip install gradio==4.44.1 gradio_litmodel3d==0.0.1
pip install triton-windows
pip install open3d

call venv\scripts\deactivate.bat
cd..

echo *** Finished TRELLIS install
echo.
echo *** Scroll up and check for errors.  Do not assume it worked.
pause

