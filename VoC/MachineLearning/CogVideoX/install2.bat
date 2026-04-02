@echo off



echo *** %time% VoC *** Deleting CogVideo directory if it exists
if exist CogVideo\. rd /S /Q CogVideo

echo *** %time% VoC *** Cloning CogVideo repository
git clone https://github.com/THUDM/CogVideo
cd CogVideo

