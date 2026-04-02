@echo off



echo *** %time% *** Deleting PersonaPlex directory if it exists
if exist PersonaPlex\. rd /S /Q PersonaPlex

echo *** %time% *** Cloning repository
git clone https://github.com/surebabu2007/Personaplex-oneclicker
ren Personaplex-oneclicker PersonaPlex
cd PersonaPlex

echo *** %time% *** Installing PersonaPlex
call INSTALL_PERSONAPLEX.bat

rem echo *** %time% *** Installing GPU torch
rem pip uninstall -y torch
rem pip uninstall -y torch
rem pip uninstall -y torch
rem pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.7.0+cu128 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128

cd ..
echo *** %time% *** Finished PersonaPlex install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause
