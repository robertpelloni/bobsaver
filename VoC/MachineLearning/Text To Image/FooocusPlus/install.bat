@echo off
cls



echo *** %time% *** Deleting FooocusPlus directory if it exists
if exist FooocusPlus\. rd /S /Q FooocusPlus

echo *** %time% *** Attempting to download FooocusPlus.7z
curl -L -o "FooocusPlus.7z" "https://huggingface.co/DavidDragonsage/FooocusPlus/resolve/main/FooocusPlus.7z" -v

echo *** %time% *** Extracting FooocusPlus.7z
7z x -y FooocusPlus.7z
echo *** %time% *** Deleting FooocusPlus.7z
del FooocusPlus.7z

echo *** %time% *** Downloading python_embedded.7z
cd FooocusPlus
curl -L -o "python_embedded.7z" "https://huggingface.co/DavidDragonsage/FooocusPlus/resolve/main/python_embedded.7z" -v
echo *** %time% *** Extracting python_embedded.7z
..\7z x -y python_embedded.7z
echo *** %time% *** Deleting python_embedded.7z
del python_embedded.7z

echo *** %time% *** Downloading StarterPack.7z
curl -L -o "StarterPack.7z" "https://huggingface.co/DavidDragonsage/FooocusPlus/resolve/main/SupportPack.7z" -v
echo *** %time% *** Extracting StarterPack.7z
..\7z x -y StarterPack.7z
echo *** %time% *** Deleting StarterPack.7z
del StarterPack.7z

echo.
echo *** %time% *** Scroll up and check for any error messages.  Do not assume the install worked. ***
pause

