@echo off
cd HunyuanVideo-Foley
call venv\scripts\activate.bat
set HIFI_FOLEY_MODEL_PATH=D:\code\Delphi\Chaos\Examples\MachineLearning\.cache\hub\models--tencent--HunyuanVideo-Foley\snapshots\3abd4e833b95b8db0fc9c687afc52483a48e9a97
python gradio_app.py
call venv\scripts\deactivate.bat
cd..
