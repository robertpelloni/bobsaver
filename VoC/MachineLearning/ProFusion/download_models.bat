@echo off
cls


echo Deleting existing model directories if they exist...
echo.
if exist pretrained. rd /S /Q pretrained
if exist identity_small. rd /S /Q identity_small

echo Downloading pretrained.zip...
echo.
if exist pretrained.zip del pretrained.zip
curl -L -o "pretrained.zip" "https://docs.google.com/uc?export=download&confirm=t&id=1n6jZXpb2nE_ptftKjSr7JZ22TsCbZHCh" -v

echo Downloading identity_small.zip...
echo.
if exist identity_small.zip del identity_small.zip
curl -L -o "identity_small.zip" "https://docs.google.com/uc?export=download&confirm=t&id=1TPPKLqkUno1WvM_cTNTZSxfzE6GTV3Xz" -v

echo Extracting pretrained.zip...
echo.
tar -v -xf pretrained.zip
del pretrained.zip

echo Extracting identity_small.zip...
echo.
tar -v -xf identity_small.zip
del identity_small.zip

echo.
pause
D:
D:

echo.
echo Downloads completed.
echo ***** Scroll up and check for any error messages.  Do not assume the downloads worked. *****
pause