@echo off
cd EveryDream
echo.
echo *** VoC - activating venv
call activate_venv.bat
echo.
echo *** VoC - starting image captioning
python scripts/auto_caption.py --img_dir "D:\Eraserhead" --out_dir "D:\Eraserhead Captioned"
echo.
echo *** VoC - finished image captioning
