@echo off




echo *** %time% *** Deleting VibeVoice-ComfyUI directory if it exists
if exist ComfyUI\custom_nodes\VibeVoice-ComfyUI\. rd /S /Q ComfyUI\custom_nodes\VibeVoice-ComfyUI

echo *** %time% *** Deleting Examples\VibeVoice directory if it exists
if exist Examples\VibeVoice\. rd /S /Q Examples\VibeVoice

echo *** %time% *** Cloning VibeVoice-ComfyUI repository
cd ComfyUI
cd custom_nodes
git clone https://github.com/Enemyx-net/VibeVoice-ComfyUI
cd..
cd..

echo *** %time% *** Installing requirements.txt
call ComfyUI\.venv\scripts\activate.bat
pip install -r ComfyUI\custom_nodes\VibeVoice-ComfyUI\requirements.txt
call ComfyUI\.venv\scripts\deactivate.bat

echo *** %time% *** Copying example workflows
md Examples\VibeVoice
copy /Y ComfyUI\custom_nodes\VibeVoice-ComfyUI\examples\*.* Examples\VibeVoice\

echo *** %time% *** Finished VibeVoice install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause

rem Text-to-Speech voice cloning
