@echo off
cls
cd Lumina-T2X
call venv\scripts\activate.bat
cd lumina_t2i
python demo.py --ckpt ..\models\Lumina-T2I
cd..
call venv\scripts\deactivate.bat
cd..
