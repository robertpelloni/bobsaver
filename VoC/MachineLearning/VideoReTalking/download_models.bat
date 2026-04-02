@echo off
cls



if exist VideoReTalking-checkpoints-001.zip del VideoReTalking-checkpoints-001.zip
if exist VideoReTalking-checkpoints-002.zip del VideoReTalking-checkpoints-002.zip

echo Downloading required models...
echo.
curl -L -o "VideoReTalking-checkpoints-001.zip" "https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/VideoReTalking-checkpoints-001.zip" -v
curl -L -o "VideoReTalking-checkpoints-002.zip" "https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/VideoReTalking-checkpoints-002.zip" -v
echo.
echo Extracting models...
echo.
7z x VideoReTalking-checkpoints-001.zip
7z x VideoReTalking-checkpoints-002.zip
echo.

if exist VideoReTalking-checkpoints-001.zip del VideoReTalking-checkpoints-001.zip
if exist VideoReTalking-checkpoints-002.zip del VideoReTalking-checkpoints-002.zip

echo.
echo Downloads completed.
echo ***** Scroll up and check for any error messages.  Do not assume the downloads worked. *****
pause