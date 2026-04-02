@echo off
cd PuLID
call venv\scripts\activate.bat

rem PuLID
rem python app.py

rem PuLID For FLUX - SLOW, but works
python app_flux.py

rem neither of these next 2 work, they need basicsr, but installing basicsr gives a "No module named 'torchvision.transforms.functional_tensor'" error
rem python app_v1_1.py --base RunDiffusion/Juggernaut-XL-v9
rem python app_v1_1.py --base Lykon/dreamshaper-xl-lightning

call venv\scripts\deactivate.bat
cd..
