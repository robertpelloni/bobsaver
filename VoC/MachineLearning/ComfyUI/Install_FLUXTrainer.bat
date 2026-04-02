@echo off




echo *** %time% *** Deleting ComfyUI-FluxTrainer directory if it exists
if exist ComfyUI\custom_nodes\ComfyUI-FluxTrainer\. rd /S /Q ComfyUI\custom_nodes\ComfyUI-FluxTrainer

echo *** %time% *** Deleting Examples\FLUXTrainer directory if it exists
if exist Examples\FLUXTrainer\. rd /S /Q Examples\FLUXTrainer

echo *** %time% *** Cloning ComfyUI-FluxTrainer repository
cd ComfyUI
cd custom_nodes
git clone https://github.com/kijai/ComfyUI-FluxTrainer
cd..
cd..

echo *** %time% *** Installing requirements.txt
call ComfyUI\.venv\scripts\activate.bat
pip install -r ComfyUI\custom_nodes\ComfyUI-FluxTrainer\requirements.txt
call ComfyUI\.venv\scripts\deactivate.bat

echo *** %time% *** Copying example workflows
md Examples\FLUXTrainer
copy /Y ComfyUI\custom_nodes\ComfyUI-FluxTrainer\example_workflows\*.* Examples\FluxTrainer\

rem skip model downloads?
if "%1"=="" goto download_models
echo *** VoC - skipping model downloads
goto skip_models
:download_models

echo *** %time% *** Downloading models
md ComfyUI\models\vae

:skip_models
echo *** %time% *** Finished FluxTrainer install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause

rem Trains FLUX LoRAs
