@echo off
cd flux
call venv\scripts\activate.bat
streamlit run demo_st.py
call venv\scripts\deactivate.bat
cd..
