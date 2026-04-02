@echo off


rem cls
rem set PYTHONUNBUFFERED=TRUE
rem set CONDA_ROOT_PREFIX=%cd%\installer_files\conda
rem set INSTALL_ENV_DIR=%cd%\installer_files\env
@rem activate installer env
rem call "%CONDA_ROOT_PREFIX%\condabin\conda.bat" activate "%INSTALL_ENV_DIR%"
rem cd text-generation-webui
call venv\scripts\activate.bat
python download-models.py
pause