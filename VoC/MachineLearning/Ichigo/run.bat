@echo off
rem cls
cd llama3-s
call venv\scripts\activate.bat
python -m demo.app --host 0.0.0.0 --port 7860 --max-seq-len 1024 
