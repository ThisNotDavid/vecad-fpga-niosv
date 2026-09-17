@echo off
pushd "%~dp0"
python host\keyboard_client.py
if errorlevel 1 pause
popd
