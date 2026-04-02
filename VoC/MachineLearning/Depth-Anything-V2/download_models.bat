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
curl -L -o "depth_anything_v2_vitl.pth" "https://huggingface.co/depth-anything/Depth-Anything-V2-Large/resolve/main/depth_anything_v2_vitl.pth" -v
cd ..

echo Finished at %date% %time%
echo.

echo Done
pause
D:
