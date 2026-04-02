@echo off
cd ACE-Step-1.5
call venv\Scripts\activate.bat
python -m acestep.acestep_v15_pipeline --server-name 127.0.0.1 --port 7860 --enable-api
call venv\scripts\deactivate.bat
cd..
