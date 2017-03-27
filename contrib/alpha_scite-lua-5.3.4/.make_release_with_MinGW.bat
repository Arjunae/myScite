::...::..:::...::..::.:.::
::    SciTE Prod   ::  
::...::..:::...::..::.:.::

@echo off
set PATH=E:\MinGW\bin;%PATH%;
setlocal

:: ... use customized CMD Terminal
if "%1"=="" (
  reg import ...\contrib\TinyTonCMD\TinyTonCMD.reg
  start "TinyTonCMD" .make_release_with_MinGW.bat tiny
  EXIT
)

echo ::..::..:::..::..::.:.::
echo ::    SciTE Prod      ::
echo ::..::..:::..::..::.:.::

::cd 3.7.0\scintilla\win32
::mingw32-make -j %NUMBER_OF_PROCESSORS%
REM tdm-make -j %NUMBER_OF_PROCESSORS%
::if errorlevel 1 goto :error

::cd ..\..\scite\win32
cd 3.7.0\scite\win32
mingw32-make deps

mingw32-make 
::-j %NUMBER_OF_PROCESSORS%
REM tdm-make -j %NUMBER_OF_PROCESSORS%

copy /Y ..\bin\SciTE.exe ..\..\..\SciTE_lua5.3.4\
::copy /Y ..\bin\SciLexer.dll ..\..\..\SciTE_lua5.3.4\

if errorlevel 1 goto :error

goto end

:error
pause

:end
cd ..\..
PAUSE
EXIT