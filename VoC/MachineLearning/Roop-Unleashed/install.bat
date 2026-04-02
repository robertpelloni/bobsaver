@echo off
set PYTHONIOENCODING=utf-8&set GIT_FLUSH=1



echo *** VoC - Deleting roop-unleashed directory if it exists
if exist roop-unleashed\. rd /S /Q roop-unleashed

echo *** VoC - git clone roop-unleashed
git clone https://github.com/C0untFloyd/roop-unleashed

echo *** VoC - stopping auto-run of Roop Unleashed at the end of the install
rem make a copy to copy back after install
copy roop-unleashed\installer\installer.py installer.bak
rem because the installer.py is auto-edited here to not auto-launch the GUI at the end of the install
type roop-unleashed\installer\installer.py | findstr /b /l /v /c:"    start_app" > installer.txt
del roop-unleashed\installer\installer.py
move installer.txt roop-unleashed\installer\installer.py

echo *** VoC - windows_run.bat
cd roop-unleashed
echo.|call installer\windows_run.bat

rem restore original backup of installer.py
cd..
del roop-unleashed\installer\installer.py
move installer.bak roop-unleashed\installer\installer.py

echo.
echo *** VoC - finished roop-unleashed install

echo.
echo *** Scroll up and check for any error messages.  Do not assume the install worked. ***
pause
