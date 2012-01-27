@echo off

cd /d %~dp0

Set install=gauche-install
Set config=gauche-config

call which %install%
if not %ERRORLEVEL% == 0 (
	echo %install% Not Found.
	goto EXIT
) 
call which %config%
if not %ERRORLEVEL% == 0 (
	echo %config% Not Found
	goto EXIT
) 

for  /f "usebackq tokens=*" %%i in (`%config% --sitelibdir`) do Set pkglibdir="%%i"
for  /f "usebackq tokens=*" %%i in (`%config% --sitearchdir`) do Set pkgarchdir="%%i"
for  /f "usebackq tokens=*" %%i in (`%config% --siteincdir`) do Set pkgincdir="%%i"

cd header
for %%d in (*.h) do  (
echo Uninstalling header file ... %%d
%install% -U %pkgincdir% %%d
)
cd ..

cd dll
for %%h in (*.dll) do  (
echo Uninstalling dll file ... %%h
%install% -U %pkgarchdir% %%h
)
cd ..


cd scm
for %%s in (*.scm) do (
echo Uninstalling scm file ... %%s
%install% -U %pkglibdir% %%s
)
for %%s in (cv\*.scm) do (
echo Uninstalling scm file ... %%s
%install% -U %pkglibdir% %%s
)
cd ..

echo Uninstall Successful!!
:EXIT

PAUSE
