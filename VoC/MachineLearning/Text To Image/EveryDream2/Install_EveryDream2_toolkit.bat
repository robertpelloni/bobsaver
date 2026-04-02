@echo off
echo.
echo *** VoC - Deleting EveryDream directory if it exists
if exist EveryDream\. rd /S /Q EveryDream
echo.
echo *** VoC - git clone
git clone https://github.com/victorchall/EveryDream
cd EveryDream
echo.
echo *** VoC - git reset
git reset --hard
echo.
echo *** VoC - git pull
git pull
echo.
echo *** VoC - finished EveryDream toolkit setup
