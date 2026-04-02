@echo off
cls



echo Started at %date% %time%
echo.

echo Deleting existing checkpoints folder if it exists...
if exist checkpoints\. rd checkpoints /s/q

echo.
echo Downloading models...
echo.
md checkpoints
cd checkpoints
curl -L -o "DUSt3R_ViTLarge_BaseDecoder_512_dpt.pth" "https://download.europe.naverlabs.com/ComputerVision/DUSt3R/DUSt3R_ViTLarge_BaseDecoder_512_dpt.pth" -v
curl -L -o "DUSt3R_ViTLarge_BaseDecoder_224_linear.pth" "https://download.europe.naverlabs.com/ComputerVision/DUSt3R/DUSt3R_ViTLarge_BaseDecoder_224_linear.pth" -v
curl -L -o "DUSt3R_ViTLarge_BaseDecoder_512_linear.pth" "https://download.europe.naverlabs.com/ComputerVision/DUSt3R/DUSt3R_ViTLarge_BaseDecoder_512_linear.pth" -v
cd ..

echo Finished at %date% %time%
echo.

echo Done
pause
