@echo off




echo *** %time% *** Deleting ComfyUI-MochiWrapper directory if it exists
if exist ComfyUI\custom_nodes\ComfyUI-MochiWrapper\. rd /S /Q ComfyUI\custom_nodes\ComfyUI-MochiWrapper

echo *** %time% *** Deleting Examples\Mochi directory if it exists
if exist Examples\Mochi\. rd /S /Q Examples\Mochi

echo *** %time% *** Cloning ComfyUI-MochiWrapper repository
cd ComfyUI
cd custom_nodes
git clone https://github.com/kijai/ComfyUI-MochiWrapper
cd..
cd..

echo *** %time% *** Installing requirements.txt
call ComfyUI\.venv\scripts\activate.bat
pip install -r ComfyUI\custom_nodes\ComfyUI-MochiWrapper\requirements.txt
call ComfyUI\.venv\scripts\deactivate.bat

echo *** %time% *** Copying example workflows
md Examples\Mochi
copy /Y ComfyUI\custom_nodes\ComfyUI-MochiWrapper\examples\*.* Examples\Mochi\

rem skip model downloads?
if "%1"=="" goto download_models
echo *** VoC - skipping model downloads
goto skip_models
:download_models

:skip_models
echo *** %time% *** Finished Mochi install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause

rem Text-to-Video