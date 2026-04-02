@echo off




echo *** %time% *** Deleting ComfyUI-MMAudio directory if it exists
if exist ComfyUI\custom_nodes\MMAudio\. rd /S /Q ComfyUI\custom_nodes\MMAudio

echo *** %time% *** Deleting Examples\MMAudio directory if it exists
if exist Examples\MMAudio\. rd /S /Q Examples\MMAudio

echo *** %time% *** Cloning ComfyUI-MMAudio repository
cd ComfyUI
cd custom_nodes
git clone https://github.com/kijai/ComfyUI-MMAudio
cd..
cd..

echo *** %time% *** Installing requirements.txt
call ComfyUI\.venv\scripts\activate.bat
pip install setuptools
pip install -r ComfyUI\custom_nodes\ComfyUI-MMAudio\requirements.txt
call ComfyUI\.venv\scripts\deactivate.bat

echo *** %time% *** Copying example workflows
md Examples\MMAudio
copy /Y ComfyUI\custom_nodes\ComfyUI-MMAudio\example_workflows\*.* Examples\MMAudio\

rem skip model downloads?
if "%1"=="" goto download_models
echo *** VoC - skipping model downloads
goto skip_models
:download_models

echo *** %time% *** Downloading models
git lfs install
if exist ComfyUI\models\MMAudio\. rd ComfyUI\models\MMAudio /s/q
md ComfyUI\models\MMAudio
cd ComfyUI\models\MMAudio
git clone https://huggingface.co/Kijai/MMAudio_safetensors
move .\MMAudio_safetensors\*.safetensors .\
rd MMAudio_safetensors /s/q

:skip_models
echo *** %time% *** Finished MMAudio install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause

rem Adds audio to videos based on the video content
