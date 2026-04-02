@echo off
cls
D:
cd "D:\code\delphi\Chaos\Examples\MachineLearning\Retrieval-based-Voice-Conversion-WebUI"

echo *** VoC - Deleting RVC-beta directory if it exists...
if exist RVC-beta\. rd /S /Q RVC-beta

echo *** VoC - Deleting tmp directory if it exists...
if exist tmp\. rd /S /Q tmp

echo *** VoC - Downloading RVC-beta.zip...
if exist RVC-beta.zip del RVC-beta.zip
curl -L -o "RVC.7z" "https://huggingface.co/lj1995/VoiceConversionWebUI/resolve/main/RVC1006Nvidia.7z" -v

echo *** VoC - Extracting RVC.zip...
7z x RVC.7z

echo *** VoC - Renaming unzipped directory ...
rename RVC1006Nvidia RVC

echo *** VoC - Deleting RVC.zip...
if exist RVC.7z del RVC.7z

echo *** VoC - Install finished

echo.
echo *** Scroll up and check for any error messages.  Do not assume the install worked. ***
pause
