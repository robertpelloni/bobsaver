@echo off
echo.
echo *** VoC - Deleting EveryDream2trainer directory if it exists
if exist EveryDream2trainer\. rd /S /Q EveryDream2trainer
echo.
echo *** VoC - git clone
git clone https://github.com/victorchall/EveryDream2trainer
cd EveryDream2trainer
echo.
echo *** VoC - git reset
git reset --hard
echo.
echo *** VoC - git pull
git pull
echo.
echo *** VoC - windows_setup.cmd
call windows_setup.cmd
echo.

echo *** VoC - finished EveryDream2 setup
