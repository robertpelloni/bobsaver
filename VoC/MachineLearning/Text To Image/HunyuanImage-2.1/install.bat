@echo off



if exist HunyuanImage-2.1\. rd /S /Q HunyuanImage-2.1

echo *** %time% *** Cloning repository
git clone https://github.com/Tencent-Hunyuan/HunyuanImage-2.1.git
cd HunyuanImage-2.1
copy ..\inference.py

echo *** Creating venv
python -m venv venv
call venv\scripts\activate.bat

echo *** %time% *** Installing requirements
python -m pip install --upgrade pip==24.3.1
pip install wheel==0.45.1
pip install setuptools==65.5.0
pip install -r requirements.txt
pip install https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/flash_attn-2.7.4.post1-cp310-cp310-win_amd64.whl

echo *** %time% *** Installing GPU torch
pip uninstall -y torch
pip uninstall -y torch
pip uninstall -y torch
pip install torch==2.7.0+cu128 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128
rem pip install gradio==5.25.2
rem pip install triton-windows==3.2.0.post17
rem pip install sentencepiece==0.2.0
rem pip install optimum==1.24.0
rem pip install auto-gptq==0.7.1
rem pip install bitsandbytes==0.45.5

echo *** %time% *** Downloading models
pip install -U "huggingface_hub[cli]"
pip install modelscope
hf download tencent/HunyuanImage-2.1 --local-dir ./ckpts
hf download Qwen/Qwen2.5-VL-7B-Instruct --local-dir ./ckpts/text_encoder/llm
hf download google/byt5-small --local-dir ./ckpts/text_encoder/byt5-small
modelscope download --model AI-ModelScope/Glyph-SDXL-v2 --local_dir ./ckpts/text_encoder/Glyph-SDXL-v2

cd ..
echo *** %time% VoC *** Finished HiDream-I1-nf4 install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause
