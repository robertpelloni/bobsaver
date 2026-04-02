@echo off



echo *** %time% *** Deleting Hunyuan3D-2 directory if it exists
if exist Hunyuan3D-2\. rd /S /Q Hunyuan3D-2

echo *** VoC - downloading Hunyuan3D2_WinPortable.7z
curl -L -o "Hunyuan3D-2.7z" "https://github.com/YanWenKun/Comfy3D-WinPortable/releases/download/r8-hunyuan3d2/Hunyuan3D2_WinPortable.7z" -v

echo *** VoC - extracting Hunyuan3D-2.7z
7z.exe x Hunyuan3D-2.7z
ren Hunyuan3D2_WinPortable Hunyuan3D-2
del Hunyuan3D-2.7z

cd Hunyuan3D-2

echo *** VoC - running install
call 1-compile-install.bat

echo *** VoC - downloading models
call 2-download-models.bat

echo *** %time% *** Finished Hunyuan3D-2 install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause
