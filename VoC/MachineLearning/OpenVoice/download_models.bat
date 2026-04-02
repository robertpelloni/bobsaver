@echo off
cls



echo Deleting checkpoints directory if it exists...

if exist chckpoints\. rd checkpoints /s/q
rem md checkpoints
rem cd checkpoints

curl -L -o "checkpoints.zip" "https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/openvoice_checkpoints.zip" -v

7z x checkpoints.zip

del checkpoints.zip

echo.
echo Downloads completed.
echo ***** Scroll up and check for any error messages.  Do not assume the downloads worked. *****
pause