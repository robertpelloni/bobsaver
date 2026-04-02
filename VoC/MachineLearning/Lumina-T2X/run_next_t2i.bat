@echo off
cls
cd Lumina-T2X
call venv\scripts\activate.bat
cd lumina_next_t2i
python demo.py --ckpt ..\models\Lumina-Next-T2I
cd..
call venv\scripts\deactivate.bat
cd..
