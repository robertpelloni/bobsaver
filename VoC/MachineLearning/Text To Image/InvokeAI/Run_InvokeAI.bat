@echo off
set PYTHONUNBUFFERED=TRUE
D:
cd "\code\delphi\Chaos\Examples\MachineLearning\Text To Image\InvokeAI\"
cd InvokeAI
echo *** VoC - activating virtual environment
call .venv\scripts\activate.bat
echo *** VoC - starting
invokeai-web
echo *** VoC - done
