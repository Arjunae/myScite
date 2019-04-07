::...::..:::...::..::.:.::
::    SciTE Prod   ::  
::...::..:::...::..::.:.::

@echo off
setlocal enabledelayedexpansion enableextensions
set PLAT=""
set PLAT_TARGET=""

:: MinGW Path has to be set, otherwise please define here:
::set PATH=E:\MinGW\bin;%PATH%;

:: ... use customized CMD Terminal
if "%1"=="" (
  reg import ..\contrib\TinyTonCMD\TinyTonCMD.reg
  start "TinyTonCMD" %~nx0 %1 tiny
  EXIT
)

if exist src\mingw.*.debug.build choice /C YN /M "A MinGW Debug Build has been found. Rebuild as Release? "
if [%ERRORLEVEL%]==[2] (
  exit
) else if [%ERRORLEVEL%]==[1] (
  cd src
  del mingw.*.debug.build 1>NUL 2>NUL
  del /S /Q *.dll *.exe *.res *.orig *.rej 1>NUL 2>NUL
  cd ..
)

echo ::..::..:::..::..::.:.::
echo ::    SciTE Prod      ::
echo ::..::..:::..::..::.:.::
echo.
where mingw32-make 1>NUL 2>NUL
if %ERRORLEVEL%==1 (
 echo Error: MSYS2/MinGW Installation was not found or its not in your systems path.
 echo.
 echo Within MSYS2, utilize 
 echo pacman -Sy mingw-w64-i686-toolchain
 echo pacman -Sy mingw-w64-x86_64-toolchain
 echo and add msys2/win32 or msys2/win64 to your systems path.
 echo.
 pause
exit
)

echo ~~~~Build: Scintilla
cd src\scintilla\win32
mingw32-make  -j %NUMBER_OF_PROCESSORS%
if [%errorlevel%] NEQ [0] goto :error
echo.
echo ~~~~Build: SciTE
cd ..\..\scite\win32
mingw32-make  -j %NUMBER_OF_PROCESSORS%
if [%errorlevel%] NEQ [0] goto :error
echo.
echo :--------------------------------------------------
echo .... done ....
echo :--------------------------------------------------

REM Find and display currents build targets Platform
set PLAT_TARGET=..\bin\SciTE.exe
call :find_platform
echo .... Targets platform [%PLAT%] ......
echo ~~~~~ Copying Files to release...
If [%PLAT%]==[win32] (
echo .... move to SciTE.win32 ......
if not exist ..\..\..\release md ..\..\..\release
copy ..\bin\SciTE.exe ..\..\..\release
copy ..\bin\SciLexer.dll ..\..\..\release
)

If [%PLAT%]==[win64] (
echo ... move to SciTE.win64
if not exist ..\..\..\release md ..\..\..\release
copy ..\bin\SciTE.exe ..\..\..\release
copy ..\bin\SciLexer.dll ..\..\..\release
)
cd ..\..\..
echo > src\mingw.%PLAT%.release.build
goto end

:error
echo Stop: An Error %ERRORLEVEL% occured during the build. 
pause

:end
PAUSE
EXIT

::--------------------------------------------------
:: Now use this littl hack to look for a platform PE Signature at offset 120+
:: Should work compiler independent for uncompressed binaries.
:: Takes: PLAT_TARGET Value: Executable to be checked
:: Returns: PLAT Value: Either WIN32 or WIN64 
:find_platform
set off32=""
set off64=""

for /f "delims=:" %%A in ('findstr /o "^.*PE..L." %PLAT_TARGET%') do (
  if [%%A] LEQ [200] SET PLAT=win32
  if [%%A] LEQ [200] SET OFFSET=%%A
)

for /f "delims=:" %%A in ('findstr /o "^.*PE..d." %PLAT_TARGET%') do (
  if [%%A] LEQ [200] SET PLAT=win64
  if [%%A] LEQ [200] SET OFFSET=%%A
)
exit /b 0
:end_sub