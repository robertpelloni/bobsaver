@echo off
cd Thera
call venv\Scripts\activate.bat
set TF_CPP_MIN_LOG_LEVEL=0
rem python super_resolve.py ..\nic_cage.jpg ..\nic_cage_thera.jpg --scale 3.14 --checkpoint models\thera-rdn-pro.pkl
python super_resolve.py ..\manga3.png ..\manga3_thera.png --scale 3.14 --checkpoint models\thera-rdn-pro.pkl
call venv\scripts\deactivate.bat
cd..
