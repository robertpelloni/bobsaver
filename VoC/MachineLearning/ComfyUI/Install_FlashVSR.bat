@echo off




echo *** %time% *** Deleting ComfyUI-FlashVSR_Ultra_Fast directory if it exists
if exist ComfyUI\custom_nodes\ComfyUI-FlashVSR_Ultra_Fast\. rd /S /Q ComfyUI\custom_nodes\ComfyUI-FlashVSR_Ultra_Fast

echo *** %time% *** Deleting Examples\FlashVSR directory if it exists
if exist Examples\FlashVSR\. rd /S /Q Examples\FlashVSR

echo *** %time% *** Cloning ComfyUI-FlashVSR_Ultra_Fast repository
cd ComfyUI
cd custom_nodes
git clone https://github.com/lihaoyun6/ComfyUI-FlashVSR_Ultra_Fast.git
cd..
cd..

echo *** %time% *** Installing requirements.txt
call ComfyUI\.venv\scripts\activate.bat
pip install -r ComfyUI\custom_nodes\ComfyUI-FlashVSR_Ultra_Fast\requirements.txt
call ComfyUI\.venv\scripts\deactivate.bat

echo *** %time% *** Downloading example workflows
md Examples\FlashVSR
curl -L -o "Examples\FlashVSR\FlashVSR.json" "https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/FlashVSR.json" -v
curl -L -o "Examples\FlashVSR\FlashVSRAdvanced.json" "https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/FlashVSRAdvanced.json" -v
curl -L -o "Examples\FlashVSR\woman-running.mp4" "https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/woman-running.mp4" -v



rem bad quality https://github.com/1038lab/ComfyUI-FlashVSR/issues/13
rem echo *** %time% *** Deleting ComfyUI-FlashVSR directory if it exists
rem if exist ComfyUI\custom_nodes\ComfyUI-FlashVSR\. rd /S /Q ComfyUI\custom_nodes\ComfyUI-FlashVSR

rem echo *** %time% *** Cloning ComfyUI-FlashVSR repository
rem cd ComfyUI
rem cd custom_nodes
rem git clone https://github.com/1038lab/ComfyUI-FlashVSR
rem cd..
rem cd..

rem echo *** %time% *** Installing requirements.txt
rem call ComfyUI\.venv\scripts\activate.bat
rem pip install -r ComfyUI\custom_nodes\ComfyUI-FlashVSR\requirements.txt
rem call ComfyUI\.venv\scripts\deactivate.bat



echo *** %time% *** Deleting ComfyUI-FlashVSR_Stable directory if it exists
if exist ComfyUI\custom_nodes\ComfyUI-FlashVSR_Stable\. rd /S /Q ComfyUI\custom_nodes\ComfyUI-FlashVSR_Stable

echo *** %time% *** Cloning ComfyUI-FlashVSR_Stable repository
cd ComfyUI
cd custom_nodes
git clone https://github.com/naxci1/ComfyUI-FlashVSR_Stable
cd..
cd..

cd ComfyUI
cd custom_nodes
cd ComfyUI-FlashVSR_Stable
echo *** Removing triton from requirements.txt
type requirements.txt | findstr /v triton > stripped.txt
del requirements.txt
ren stripped.txt requirements.txt

echo *** Removing flash-attn from requirements.txt
type requirements.txt | findstr /v flash > stripped.txt
del requirements.txt
ren stripped.txt requirements.txt
cd..
cd..
cd..

echo *** %time% *** Installing requirements.txt
call ComfyUI\.venv\scripts\activate.bat
pip install -r ComfyUI\custom_nodes\ComfyUI-FlashVSR_Stable\requirements.txt
call ComfyUI\.venv\scripts\deactivate.bat








echo *** %time% *** Finished FlashVSR install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause

rem Video Upscaling for small/short movies only
