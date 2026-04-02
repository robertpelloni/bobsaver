@echo off
cd FaceFusion\FaceFusion
call venv\scripts\activate
python facefusion.py run --execution-providers cuda
call venv\scripts\deactivate
cd..
cd..
