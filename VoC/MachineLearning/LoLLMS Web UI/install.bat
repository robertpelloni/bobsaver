@echo off
cls



echo *** VoC - Deleting installer_files directory if it exists
if exist installer_files\. rd /S /Q installer_files

echo *** VoC - Deleting lollms-webui directory if it exists
if exist lollms-webui\. rd /S /Q lollms-webui

echo *** VoC - Downloading latest win_install.bat ...
curl -L -o "win_install.bat" "https://github.com/ParisNeo/lollms-webui/releases/download/v12/win_install.bat" -v

echo *** VoC - Installing ...
call win_install.bat

echo *** VoC - Install finished.

echo.
echo *** Scroll up and check for any error messages.  Do not assume the install worked. ***
pause
