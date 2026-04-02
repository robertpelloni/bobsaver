@echo off




echo *** %time% *** Deleting Examples\DeforumFLUX directory if it exists
if exist Examples\DeforumFLUX\. rd /S /Q Examples\DeforumFLUX

echo *** %time% *** Downloading example workflows
md Examples\DeforumFLUX
curl -L -o "Examples\DeforumFLUX\deforum_flux_complex_v0.0.3.json" "https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/deforum_flux_complex_v0.0.3.json" -v

echo *** %time% *** Finished DeforumFLUX install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause

rem Recursize zoom movies