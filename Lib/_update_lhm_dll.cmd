@echo off
:: LibreHardwareMonitorLib DLL-Update (automatisch generiert von Bockis System-Tool)
timeout /t 3 /nobreak > nul
if exist "%~dp0LibreHardwareMonitorLib.dll" (
    move /y "%~dp0LibreHardwareMonitorLib.dll" "%~dp0LibreHardwareMonitorLib.dll.old" > nul
)
move /y "%~dp0LibreHardwareMonitorLib.dll.new" "%~dp0LibreHardwareMonitorLib.dll" > nul
del "%~f0"