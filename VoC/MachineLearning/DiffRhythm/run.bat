@echo off
cd DiffRhythm
set PHONEMIZER_ESPEAK_LIBRARY=C:\Program Files\eSpeak NG\libespeak-ng.dll
call venv\Scripts\activate.bat
python infer.py --lrc-path "D:\code\delphi\Chaos\Examples\MachineLearning\DiffRhythm\lyrics.lrc" --ref-prompt "classical genres, hopeful mood, piano" --audio-length 95 --output-dir "D:\VoC_Output\Sounds\DiffRhythm" --chunked
call venv\scripts\deactivate.bat
cd..
