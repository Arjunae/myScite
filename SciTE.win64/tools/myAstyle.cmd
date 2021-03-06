@echo off 
:: -------- Containery for SciTE ----------
:: Provides customized Language Packs within respective Directories. 
:: ---------------------------------------

set toolFolder=beautifier\astyle
set toolName=astyle
set toolExt=.exe
set toolParam=--style=attach --indent=force-tab=8 --keep-one-line-blocks --pad-header --unpad-paren --pad-comma --indent-cases --align-pointer=name %*
::set optPath=%~dp0%..\

:: A value of 1 will instruct the wrapper to initially limit %PATH% to toolNames Directory. 
set sandbox=0

:: -------- No need to edit below here ---------- ::

:: ~dp0 = Full Path to current Directory with trailing slash
set toolPath=%~dp0%toolFolder%

:: temporarly prefix local Path with toolPath 
set path=%toolPath%;%optPath%;%path%;
if [%sandbox%]==[1] ( set path=%toolPath%;%optPath%;%~dp0%)
if [%sandbox%]==[1] ( set mode=[Sandboxed]) else ( set mode= )

:: first try if a user had installed a local package
if exist %toolPath%\%toolName%%toolExt% (
echo ~ wrapper ~ %mode% [%~dp0%toolFolder%] %toolName%%toolExt% %toolParam% >&2
%toolPath%\%toolName%%toolExt% %toolParam%
goto :freude
) 

if [%sandbox%]==[1] goto :err
:: not in restricted Mode ; ok to look for %toolName% within the system 
where /Q %toolName%%toolExt%

IF %ERRORLEVEL% == 0 (
REM  echo ~ WRapper: %toolPath%\%toolName%%toolExt% %toolParam% >&2
where %toolName%%toolExt%
%toolName%%toolExt% %toolParam%
goto :freude ) else (  goto :err )

:err
echo ... please install %toolName% or copy a custom pack to 
echo ... %toolPath%

:freude