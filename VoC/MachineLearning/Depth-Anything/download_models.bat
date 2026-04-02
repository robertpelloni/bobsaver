@echo off
cls



echo Started at %date% %time%
echo.

echo Deleting existing checkpoints folder if it exists...
if exist checkpoints\. rd checkpoints /s/q

echo.
echo Downloading model...
echo.
md checkpoints
cd checkpoints
curl -L -o "depth_anything_vitl14.pth" "https://huggingface.co/spaces/LiheYoung/Depth-Anything/resolve/main/checkpoints/depth_anything_vitl14.pth" -v
cd ..

echo Finished at %date% %time%
echo.

echo Done
pause
D:
D:
