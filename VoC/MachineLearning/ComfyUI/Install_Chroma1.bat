@echo off




echo *** %time% *** Deleting Examples\Chroma1 directory if it exists
if exist Examples\Chroma1\. rd /S /Q Examples\Chroma1

echo *** %time% *** Downloading example workflows
md Examples\Chroma1
curl -L -o "Examples\Chroma1\Chroma1.rar" "https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/Chroma1.rar" -v
cd Examples\Chroma1
..\..\7z.exe x Chroma1.rar
del Chroma1.rar
cd..
cd..

echo *** %time% *** Finished Chroma1 install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause

rem Uncensored NSFW capable Text-to-Image
