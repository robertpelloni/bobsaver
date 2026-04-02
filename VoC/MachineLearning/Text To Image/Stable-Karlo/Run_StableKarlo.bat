@echo off
call "D:\code\Delphi\Chaos\Examples\MachineLearning\venv\voc_stablekarlo\scripts\activate.bat"
echo *** VoC - starting
echo. | streamlit run app.py --browser.gatherUsageStats False
echo *** VoC - done
