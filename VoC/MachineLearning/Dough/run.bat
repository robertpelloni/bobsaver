@echo off



cd Dough
call dough-env\scripts\activate.bat
call scripts\entrypoint.bat
call dough_env\scripts\deactivate.bat
cd..
