@echo off



echo *** %time% VoC *** Deleting Tiled_ZoeDepth  directory if it exists
if exist Tiled_ZoeDepth\. rd /S /Q Tiled_ZoeDepth

echo *** Downloading Tiled ZoeDepth zip
curl -L -o "Tiled_ZoeDepth.zip" "https://github.com/n8ventures/TilingZoeDepth_GUI/releases/download/3.1.0/Tiled_ZoeDepth.7z" -v
echo *** Extracting zip
7z x Tiled_ZoeDepth.zip
del Tiled_ZoeDepth.zip

echo *** %time% VoC *** Finished Tiled ZoeDepth install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause
