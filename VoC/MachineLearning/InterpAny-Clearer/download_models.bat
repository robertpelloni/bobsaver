@echo off
 
D:
cd "D:\code\Delphi\Chaos\Examples\MachineLearning\InterpAny-Clearer"

if exist Checkpoints\. rd Checkpoints /s/q
md Checkpoints
if exist checkpoints.zip del /q checkpoints.zip
curl -L -o "Checkpoints.zip" "https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/InterpAny-Clearer.zip?download=true" -v
7z x checkpoints.zip
if exist checkpoints.zip del /q checkpoints.zip

echo.
echo Downloads completed.
echo ***** Scroll up and check for any error messages.  Do not assume the downloads worked. *****
pause