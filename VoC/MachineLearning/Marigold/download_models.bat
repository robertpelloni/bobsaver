@echo off
cls



echo Started at %date% %time%
echo.

echo Deleting existing checkpoint folder if it exists...
if exist checkpoint\. rd checkpoint /s/q

echo.
echo Downloading model...
echo.
md checkpoint
cd checkpoint
curl -L -o "Marigold_v1_merged_2.tar" "https://share.phys.ethz.ch/~pf/bingkedata/marigold/Marigold_v1_merged_2.tar" -v
..\7z x Marigold_v1_merged_2.tar
del Marigold_v1_merged_2.tar
cd ..

echo Finished at %date% %time%
echo.

echo Done
pause