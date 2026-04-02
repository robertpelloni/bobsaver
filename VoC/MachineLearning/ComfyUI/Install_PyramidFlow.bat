@echo off




echo *** %time% *** Deleting ComfyUI-PyramidFlowWrapper directory if it exists
if exist ComfyUI\custom_nodes\ComfyUI-PyramidFlowWrapper\. rd /S /Q ComfyUI\custom_nodes\ComfyUI-PyramidFlowWrapper

echo *** %time% *** Deleting Examples\PyramidFlow directory if it exists
if exist Examples\PyramidFlow\. rd /S /Q Examples\PyramidFlow

echo *** %time% *** Cloning ComfyUI-PyramidFlowWrapper repository
cd ComfyUI
cd custom_nodes
git clone https://github.com/kijai/ComfyUI-PyramidFlowWrapper
cd..
cd..

echo *** %time% *** Installing requirements.txt
call ComfyUI\.venv\scripts\activate.bat
pip install -r ComfyUI\custom_nodes\ComfyUI-PyramidFlowWrapper\requirements.txt
rem pip install sageattention
rem pip install https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/triton-2.1.0-cp310-cp310-win_amd64.whl
call ComfyUI\.venv\scripts\deactivate.bat

echo *** %time% *** Copying example workflows
md Examples\PyramidFlow
copy /Y ComfyUI\custom_nodes\ComfyUI-PyramidFlowWrapper\examples\*.* Examples\PyramidFlow\

rem skip model downloads?
if "%1"=="" goto download_models
echo *** VoC - skipping model downloads
goto skip_models
:download_models

:skip_models
echo *** %time% *** Finished PyramidFlow install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause

rem Image-to-Video, Text-to-Video
