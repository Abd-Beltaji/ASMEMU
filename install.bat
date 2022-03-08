@echo off

setlocal
call :setESC

echo %ESC%[36mASMEMU%ESC%[35m^|%ESC%[0m%ESC%[94mInstalling ASMEMU%ESC%[0m

IF NOT EXIST "bin/Debug/DEBUG.COM" (
    echo %ESC%[36mASMEMU%ESC%[35m^|%ESC%[0m%ESC%[52mBuilding DEBUG...%ESC%[0m
    cd bin/Debug
    call MAKE.BAT
    cd ../../
)

SET F="%localappdata%\ASMEMU"
IF EXIST %F% RMDIR /S /Q %F%
mkdir %F%

echo %ESC%[36mASMEMU%ESC%[35m^|%ESC%[0m%ESC%[32mCopying files%ESC%[0m
xcopy /y /s /exclude:excludedfileslist.txt "." %F%

set F=%F:"=%


echo %ESC%[36mASMEMU%ESC%[35m^|%ESC%[0m%ESC%[52mAdding folder to 'PATH'...%ESC%[0m
SET "PATH=%PATH%;%F%;"
powershell -command "[Environment]::SetEnvironmentVariable('PATH', $Env:PATH + ';%F%', 'User')"


echo %ESC%[36mASMEMU%ESC%[35m^|%ESC%[0m%ESC%[52mDefining 'ASMEMU' variable...%ESC%[0m
SET "ASMEMU=%F%"
powershell -command "[Environment]::SetEnvironmentVariable('ASMEMU', '%F%', 'User')"


echo %ESC%[36mASMEMU%ESC%[35m^|%ESC%[0m%ESC%[32mInstalled successfully...%ESC%[0m

pause

:setESC
FOR /F "tokens=1,2 delims=#" %%a IN ('"prompt #$H#$E# & echo on & for %%b in (1) do rem"') DO (
  set ESC=%%b
  exit /B 0
)
exit /B 0
