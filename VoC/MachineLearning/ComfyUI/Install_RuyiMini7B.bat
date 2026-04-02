@echo off




echo *** %time% *** Deleting Ruyi-Models directory if it exists
if exist ComfyUI\custom_nodes\Ruyi-Models\. rd /S /Q ComfyUI\custom_nodes\Ruyi-Models

echo *** %time% *** Deleting Examples\RuyiMini7B directory if it exists
if exist Examples\RuyiMini7B\. rd /S /Q Examples\RuyiMini7B

rem skip model downloads?
if "%1"=="" goto download_models
echo *** VoC - skipping model downloads
goto skip_models
:download_models

echo *** %time% *** Cloning Ruyi-Models repository
cd ComfyUI
cd custom_nodes
git clone https://github.com/IamCreateAI/Ruyi-Models
cd..
cd..

:skip_models
echo *** %time% *** Installing requirements.txt
call ComfyUI\.venv\scripts\activate.bat
pip install -r ComfyUI\custom_nodes\Ruyi-Models\requirements.txt
call ComfyUI\.venv\scripts\deactivate.bat

echo *** %time% *** Cloning ComfyUI-VideoHelperSuite
cd ComfyUI
cd custom_nodes
git clone https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite
cd..
cd..

echo *** %time% *** Installing requirements.txt
call ComfyUI\.venv\scripts\activate.bat
pip install -r ComfyUI\custom_nodes\ComfyUI-VideoHelperSuite\requirements.txt

echo *** %time% *** Patching diffusers
pip uninstall -y diffusers
pip install diffusers==0.29.2

call ComfyUI\.venv\scripts\deactivate.bat

echo *** %time% *** Copying example workflows
md Examples\RuyiMini7B
copy /Y ComfyUI\custom_nodes\Ruyi-Models\comfyui\workflows\*.* Examples\RuyiMini7B\

echo *** %time% *** Finished RuyiMini7B install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause

rem Image-to-Video
