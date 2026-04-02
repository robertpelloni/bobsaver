@echo off



echo *** %time% *** Deleting ComfyUIPortable directory if it exists
if exist ComfyUIPortable\. rd /S /Q ComfyUIPortable

echo *** %time% *** Downloading ComfyUIPortable zip file
curl -L -o ComfyUIPortable.zip https://github.com/comfyanonymous/ComfyUI/releases/latest/download/ComfyUI_windows_portable_nvidia.7z -v

echo *** %time% *** Extracting ComfyUIPortable zip file
7z x ComfyUIPortable.zip
del ComfyUIPortable.zip
ren ComfyUI_windows_portable ComfyUIPortable

echo *** %time% *** Finished ComfyUIPortable install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause
