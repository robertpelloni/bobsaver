@echo off
set PYTHONUNBUFFERED=TRUE
D:
cd "\code\Delphi\Chaos\Examples\MachineLearning\FlexGen\"
cd Flexgen
echo *** VoC - activating virtual environment
call .venv\scripts\activate.bat
echo *** VoC - starting
python flexgen\apps\chatbot.py --model facebook/OPT-30B --compress-weight --compress-cache --percent 100 0 100 0 100 0 --path "./opt_weights"
echo *** VoC - done
