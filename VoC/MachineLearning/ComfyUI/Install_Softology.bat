@echo off




echo *** %time% *** Cloning ComfyUI-Easy-Use
cd ComfyUI
cd custom_nodes
if exist ComfyUI-Easy-Use\. rd /S /Q ComfyUI-Easy-Use
git clone --revision=9f42ead9dba1a3ccaf74dfb78440f5b63318bdd9 https://github.com/yolain/ComfyUI-Easy-Use
rem cd ComfyUI-Easy-Use
rem pip install -r requirements.txt
rem cd..
cd..
cd..

goto skip

echo *** %time% *** Cloning ComfyUI_essentials
cd ComfyUI
cd custom_nodes
if exist ComfyUI_essentials\. rd /S /Q ComfyUI_essentials
git clone --revision=9d9f4bedfc9f0321c19faf71855e228c93bd0dc9 https://github.com/cubiq/ComfyUI_essentials
rem cd ComfyUI_essentials
rem pip install -r requirements.txt
cd..
cd..

echo *** %time% *** Cloning was-node-suite-comfyui
cd ComfyUI
cd custom_nodes
if exist was-node-suite-comfyui\. rd /S /Q was-node-suite-comfyui
git clone --revision=afeee09ba44e713ec52a413ac6b105fd06b2d356 https://github.com/ltdrdata/was-node-suite-comfyui
rem cd was-node-suite-comfyui
rem pip install -r requirements.txt
cd..
cd..

echo *** %time% *** ComfyUI-load-lora-from-url
cd ComfyUI
cd custom_nodes
if exist ComfyUI-load-lora-from-url\. rd /S /Q ComfyUI-load-lora-from-url
git clone --revision=05c1cfe0a52ea1256c21c7b000820fcfbfa35726 https://github.com/bollerdominik/ComfyUI-load-lora-from-url
rem cd ComfyUI-load-lora-from-url
rem pip install -r requirements.txt
cd..
cd..

:skip

echo *** %time% *** Installing requirements
pip install opencv-python

echo *** %time% *** Downloading example workflows
md Examples
if exist Examples\Softology\. rd Examples\Softology /s/q
md Examples\Softology

cd Examples\Softology
curl -L -o "ComfyUI.rar" "https://softology.pro/ComfyUI/ComfyUI.rar" -v
..\..\7z x ComfyUI.rar
del ComfyUI.rar
cd..
cd..

copy Examples\Softology\ScarlettJohansson1024x1024.png ComfyUI\input\ScarlettJohansson1024x1024.png

echo *** %time% *** Finished Softology install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause

rem Recursive video creation
