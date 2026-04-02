@echo off
set PYTHONUNBUFFERED=TRUE
D:
cd "\code\Delphi\Chaos\Examples\MachineLearning\StableTuner\"
cd StableTuner
echo *** VoC - activating virtual environment
call .venv\scripts\activate.bat
echo *** VoC - starting
python -u -B -W ignore "D:\code\Delphi\Chaos\Examples\MachineLearning\StableTuner\StableTuner\scripts\configuration_gui.py"
echo *** VoC - done
