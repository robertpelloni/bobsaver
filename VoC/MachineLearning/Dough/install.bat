@echo off

D:
cd "D:\code\delphi\Chaos\Examples\MachineLearning\Dough\"

echo *** VoC - Deleting Dough directory if it exists
if exist Dough\. rd /S /Q Dough
echo *** VoC - Downloading Dough install batch file
del windows_setup.bat
curl -L -o windows_setup.bat https://raw.githubusercontent.com/banodoco/Dough/green-head/scripts/windows_setup.bat -v
echo *** VoC - Running Dough install batch file
call windows_setup.bat
del windows_setup.bat
echo *** VoC - finished Dough install
pause

