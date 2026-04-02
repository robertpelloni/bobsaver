@echo off
echo *** VoC - updating from git repository
git config --global --add safe.directory "D:\code\Delphi\Chaos\Examples\MachineLearning\StableTuner\StableTuner"
git reset --hard
git pull
echo *** VoC - done
