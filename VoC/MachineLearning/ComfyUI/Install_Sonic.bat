@echo off




echo *** %time% *** Deleting ComfyUI-Sonic directory if it exists
if exist ComfyUI\custom_nodes\ComfyUI-Sonic\. rd /S /Q ComfyUI\custom_nodes\ComfyUI-Sonic

echo *** %time% *** Deleting Examples\Sonic directory if it exists
if exist Examples\Sonic\. rd /S /Q Examples\Sonic

echo *** %time% *** Cloning ComfyUI-Sonic repository
cd ComfyUI
cd custom_nodes
git clone https://github.com/smthemex/ComfyUI_Sonic
cd..
cd..

echo *** %time% *** Installing requirements.txt
call ComfyUI\.venv\scripts\activate.bat
pip install -r ComfyUI\custom_nodes\ComfyUI_Sonic\requirements.txt

echo *** %time% *** Copying example workflows
md Examples
if exist Examples\Sonic\. rd Examples\Sonic /s/q
md Examples\Sonic

copy ComfyUI\custom_nodes\ComfyUI_Sonic\examples\image\*.* Examples\Sonic
copy ComfyUI\custom_nodes\ComfyUI_Sonic\examples\wav\*.* Examples\Sonic
copy ComfyUI\custom_nodes\ComfyUI_Sonic\example_workflows\*.json Examples\Sonic

rem skip model downloads?
if "%1"=="" goto download_models
echo *** VoC - skipping model downloads
goto skip_models
:download_models

echo *** %time% *** Downloading models
cd ComfyUI
cd models
curl -L -o "sonic.rar" "https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/sonic.rar" -v
..\..\7z x sonic.rar
del sonic.rar
cd..
cd..

:skip_models
echo *** %time% *** Finished Sonic install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause

rem Animate portrait images with sound files
