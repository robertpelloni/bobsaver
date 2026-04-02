@echo off




echo *** Deleting Open-Sora-Plan directory if it exists
if exist Open-Sora-Plan\. rd /S /Q Open-Sora-Plan

echo *** Cloning Open-Sora-Plan repository
git clone https://github.com/PKU-YuanGroup/Open-Sora-Plan

echo *** Cloning models
cd Open-Sora-Plan
md models
cd models
git clone https://huggingface.co/LanguageBind/Open-Sora-Plan-v1.2.0

echo *** Finished Open-Sora-Plan install
echo.
echo *** Scroll up and check for errors.  Do not assume it worked.
pause


