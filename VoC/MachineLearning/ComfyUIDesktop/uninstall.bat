@echo off

C:
cd \
echo *** %time% *** Uninstalling ComfyUI Desktop...
if exist "C:\ComfyUIDesktop\." rd "C:\ComfyUIDesktop" /s/q
if exist "C:\Users\Jason\AppData\Local\Programs\@comfyorgcomfyui-electron\." rd "C:\Users\Jason\AppData\Local\Programs\@comfyorgcomfyui-electron" /s/q
if exist "C:\Users\Jason\AppData\Local\@comfyorgcomfyui-electron-updater\." rd "C:\Users\Jason\AppData\Local\@comfyorgcomfyui-electron-updater" /s/q
if exist "C:\Users\Jason\AppData\Roaming\ComfyUI\." rd "C:\Users\Jason\AppData\Roaming\ComfyUI" /s/q
echo *** %time% *** Finished ComfyUI Desktop uninstall
echo.
pause
