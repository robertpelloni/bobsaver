@echo off



rem echo *** %time% *** Deleting ComfyUIPortable directory if it exists
rem if exist ComfyUIPortable\. rd /S /Q ComfyUIPortable

echo *** %time% *** Downloading ComfyUI Desktop install
curl -L -o ComfyUIDesktop.exe https://download.comfy.org/windows/nsis/x64 -v

echo *** %time% *** Running installer
cmd /c ComfyUIDesktop.exe
del ComfyUIDesktop.exe

echo *** %time% *** Finished ComfyUI Desktop install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause
