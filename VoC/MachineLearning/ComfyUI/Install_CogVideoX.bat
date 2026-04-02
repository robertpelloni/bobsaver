@echo off




echo *** %time% *** Deleting ComfyUI-CogVideoXWrapper directory if it exists
if exist ComfyUI\custom_nodes\ComfyUI-CogVideoXWrapper\. rd /S /Q ComfyUI\custom_nodes\ComfyUI-CogVideoXWrapper

echo *** %time% *** Deleting Examples\CogVideoX directory if it exists
if exist Examples\CogVideoX\. rd /S /Q Examples\CogVideoX

echo *** %time% *** Cloning ComfyUI-CogVideoXWrapper repository
cd ComfyUI
cd custom_nodes
git clone https://github.com/kijai/ComfyUI-CogVideoXWrapper
cd..
cd..

echo *** %time% *** Installing requirements.txt
call ComfyUI\.venv\scripts\activate.bat
pip install -r ComfyUI\custom_nodes\ComfyUI-CogVideoXWrapper\requirements.txt
call ComfyUI\.venv\scripts\deactivate.bat

echo *** %time% *** Copying example workflows
md Examples
md Examples\CogVideoX
copy /Y ComfyUI\custom_nodes\ComfyUI-CogVideoXWrapper\example_workflows\*.* Examples\CogVideoX\

rem skip model downloads?
if "%1"=="" goto download_models
echo *** VoC - skipping model downloads
goto skip_models
:download_models

echo *** %time% *** Downloading other models
if not exist ComfyUI\models\CogVideo\. md ComfyUI\models\CogVideo
if exist ComfyUI\models\CogVideo\CogVideoX-5b-1.5\. rd /S /Q ComfyUI\models\CogVideo\CogVideoX-5b-1.5
cd ComfyUI\models\CogVideo\
git lfs install
git clone https://huggingface.co/Kijai/CogVideoX-5b-1.5

:skip_models
echo *** %time% *** Finished ComfyUI-CogVideoX install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause

rem Image-to-Video, Text-to-Video, Video-to-Video
