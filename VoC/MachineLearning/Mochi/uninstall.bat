@echo off



echo *** %time% *** Uninstalling Mochi...
if exist mochi-preview-standalone\. rd /S /Q mochi-preview-standalone
echo *** %time% *** Finished Mochi uninstall
echo.
pause
