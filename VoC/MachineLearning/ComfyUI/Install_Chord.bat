@echo off




echo *** %time% *** Deleting ComfyUI-Chord directory if it exists
if exist ComfyUI\custom_nodes\ComfyUI-Chord\. rd /S /Q ComfyUI\custom_nodes\ComfyUI-Chord

echo *** %time% *** Deleting Examples\Chord directory if it exists
if exist Examples\Chord\. rd /S /Q Examples\Chord

echo *** %time% *** Cloning ComfyUI-Chord repository
cd ComfyUI
cd custom_nodes
git clone --recursive https://github.com/ubisoft/ComfyUI-Chord.git
cd..
cd..

echo *** %time% *** Installing requirements.txt
call ComfyUI\.venv\scripts\activate.bat
pip install -r ComfyUI\custom_nodes\ComfyUI-Chord\requirements.txt
call ComfyUI\.venv\scripts\deactivate.bat

echo *** %time% *** Copying example workflows
md Examples
md Examples\Chord
copy /Y ComfyUI\custom_nodes\ComfyUI-Chord\example_workflows\*.* Examples\Chord\

echo *** %time% *** Finished CHORD install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause

rem Generates PBR textures
