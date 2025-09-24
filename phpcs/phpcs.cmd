@echo off
SETLOCAL ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION
set bindir=%~dp0
set target=%~f1
set work=%target%\

if not exist "%target%" (
	echo Target not found '%target%'
	goto :eof
)

type "%target%" >nul 2>nul && (for %%I in ("%target%") do set work=%%~dpI)

if exist "%work%phpcs.xml" (
    echo OUTPUT %work%\PHPCS-report.txt
	set params="--standard=%work%phpcs.xml"
) else (
    echo OUTPUT %bindir%\PHPCS-report.txt
	set params="--standard=%bindir%phpcs.xml"
)

echo on
"%bindir%vendor\bin\phpcs" %params% "%target%" %2 %3 %4 %5 %6 %7 %8 %9
