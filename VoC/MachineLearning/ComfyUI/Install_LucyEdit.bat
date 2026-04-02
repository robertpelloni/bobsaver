@echo off




echo *** %time% *** Deleting lucy-edit-comfyui directory if it exists
if exist ComfyUI\custom_nodes\lucy-edit-comfyui\. rd /S /Q ComfyUI\custom_nodes\lucy-edit-comfyui

echo *** %time% *** Deleting Examples\LucyEdit directory if it exists
if exist Examples\LucyEdit\. rd /S /Q Examples\LucyEdit

echo *** %time% *** Cloning lucy-edit-comfyui repository
cd ComfyUI
cd custom_nodes
git clone https://github.com/decartAI/lucy-edit-comfyui
cd..
cd..

echo *** %time% *** Installing requirements.txt
call ComfyUI\.venv\scripts\activate.bat
pip install -r ComfyUI\custom_nodes\lucy-edit-comfyui\requirements.txt
call ComfyUI\.venv\scripts\deactivate.bat

echo *** %time% *** Copying example workflows
md Examples\LucyEdit
copy /Y ComfyUI\custom_nodes\lucy-edit-comfyui\examples\*.* Examples\LucyEdit\

echo *** %time% *** Finished LucyEdit install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause

rem Video editing
