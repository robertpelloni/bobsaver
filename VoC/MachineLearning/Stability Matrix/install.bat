@echo off

D:
cd "D:\code\delphi\Chaos\Examples\MachineLearning\Stability Matrix\"
echo *** %time% VoC *** Deleting StabilityMatrix-win-x64.zip if it exists
if exist StabilityMatrix-win-x64.zip del StabilityMatrix-win-x64.zip

echo *** %time% VoC *** Deleting StabilityMatrix.exe if it exists
if exist StabilityMatrix.exe del StabilityMatrix.exe

echo *** %time% VoC *** Downloading latest StabilityMatrix-win-x64.zip
curl -L -o "StabilityMatrix-win-x64.zip" "https://github.com/LykosAI/StabilityMatrix/releases/latest/download/StabilityMatrix-win-x64.zip" -v

echo *** %time% VoC *** Unzipping latest StabilityMatrix-win-x64.zip
7z.exe x StabilityMatrix-win-x64.zip
del StabilityMatrix-win-x64.zip

echo *** %time% VoC *** Finished Stability Matrix install
pause
