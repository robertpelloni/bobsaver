@echo off
rem cls
cd ToonCrafter
call venv\scripts\activate.bat
if exist checkpoints\tooncrafter_512_interp_v1\model.ckpt goto skip_warning
echo First run downloads a 10 GB model.  Check Task Manager for network activity.
:skip_warning
python gradio_app.py
call venv\scripts\deactivate.bat
cd..
