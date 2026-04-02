@echo off



set PYTHONUNBUFFERED=TRUE
set PYTHONLEGACYWINDOWSSTDIO=utf-8
cd FramePack
set "PATH=%CD%\FramePack\system\python\Scripts;%PATH%"
echo %PATH%
echo.
echo.
echo *** %time% VoC *** IMPORTANT NOTE
echo *** %time% VoC *** If you use Firefox the generated movies will
echo *** %time% VoC *** not show correctly in the UI, but if you save
echo *** %time% VoC *** them to a mp4 file from the UI they will work.
echo.
rem echo *** %time% VoC *** Patching requirements
rem Remove pause from update.bat
findstr /V "pause" update.bat > update_patched.bat
del update.bat
ren update_patched.bat update.bat

call update.bat
call run.bat
cd..