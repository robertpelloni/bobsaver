@echo off



echo *** %time% *** Deleting Abogen directory if it exists
if exist Abogen\. rd /S /Q Abogen

echo *** Downloading Abogen zip
curl -L -o "main.zip" "https://github.com/denizsafak/abogen/archive/refs/heads/main.zip" -v

echo *** Extracting zip
7z x main.zip
del main.zip
ren abogen-main Abogen

echo *** Installing Abogen
cd Abogen
call WINDOWS_INSTALL.bat

echo *** Finished Abogen install
echo.
echo *** Scroll up and check for errors.  Do not assume it worked.
pause
