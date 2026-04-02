@echo off



echo *** %time% VoC *** Downloading bark-infinity-v0.23.zip
curl -L -o bark-infinity-v0.23.zip https://github.com/JonathanFly/bark-installer/releases/download/bark-infinity-v0.23b/bark-infinity-v0.23.zip -v

echo *** %time% VoC *** Extracting bark-infinity-v0.23.zip
7z x bark-infinity-v0.23.zip

echo *** Removing pause from install
findstr /V "pause" INSTALL_BARK_INFINITY.bat > INSTALL_BARK_INFINITY_PATCHED.bat
del INSTALL_BARK_INFINITY.bat
ren INSTALL_BARK_INFINITY_PATCHED.bat INSTALL_BARK_INFINITY.bat

echo *** Removing PAUSE from install
findstr /V "PAUSE" INSTALL_BARK_INFINITY.bat > INSTALL_BARK_INFINITY_PATCHED.bat
del INSTALL_BARK_INFINITY.bat
ren INSTALL_BARK_INFINITY_PATCHED.bat INSTALL_BARK_INFINITY.bat

echo *** %time% VoC *** Running installer
call INSTALL_BARK_INFINITY.bat

echo *** %time% VoC *** Finished install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause
