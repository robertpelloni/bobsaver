@echo off
cd MatAnyone
call venv\Scripts\activate.bat
cd hugging_face
python app.py
cd ..
call venv\scripts\deactivate.bat
cd..
