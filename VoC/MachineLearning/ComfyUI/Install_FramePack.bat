@echo off




echo *** %time% *** Deleting ComfyUI-FramePackWrapper directory if it exists
if exist ComfyUI\custom_nodes\ComfyUI-FramePackWrapper\. rd /S /Q ComfyUI\custom_nodes\ComfyUI-FramePackWrapper

echo *** %time% *** Deleting Examples\FramePack directory if it exists
if exist Examples\FramePack\. rd /S /Q Examples\FramePack

echo *** %time% *** Cloning ComfyUI-CogVideoXWrapper repository
cd ComfyUI
cd custom_nodes
git clone https://github.com/kijai/ComfyUI-FramePackWrapper
cd..
cd..

echo *** %time% *** Installing requirements.txt
call ComfyUI\.venv\scripts\activate.bat
pip install -r ComfyUI\custom_nodes\ComfyUI-FramePackWrapper\requirements.txt
call ComfyUI\.venv\scripts\deactivate.bat

echo *** %time% *** Downloading example workflow
md Examples
md Examples\FramePack
rem copy /Y ComfyUI\custom_nodes\ComfyUI-FramePackWrapper\example_workflows\*.* Examples\FramePack\
curl -L -o "Examples\FramePack\Shrek.png" "https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/Shrek.png" -v
curl -L -o "Examples\FramePack\framepack_start_image.json" "https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/framepack_start_image.json" -v
cd..
cd..

echo *** %time% *** Finished FramePack install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause

rem Image-to-Video
