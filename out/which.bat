@echo off
set found=
for %%I in (%1 %1.com %1.exe %1.bat %1.cmd %1.vbs %1.js %1.wsf) do if exist %%~$path:I set found=%%~$path:I
if "%found%x" NEQ "x" (
exit /b 0
) else (
exit /b 1
)
