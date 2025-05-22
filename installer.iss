; -- installer.iss für Bockis-Win_Gui --
[Setup]
AppName=Bockis System-Tool
AppVersion=3.1
DefaultDirName={autopf}\Bockis-Win_Gui
DefaultGroupName=Bockis System-Tool
UninstallDisplayIcon={app}\Win_Gui_Module.ps1
OutputDir=.
OutputBaseFilename=Bockis-Win_Gui_Setup
Compression=lzma
SolidCompression=yes

[Files]
Source: "Win_Gui_Module.ps1"; DestDir: "{app}"; Flags: ignoreversion
Source: "config.json"; DestDir: "{app}"; Flags: ignoreversion
Source: "README.md"; DestDir: "{app}"; Flags: ignoreversion
Source: "gui_closing.log*"; DestDir: "{app}"; Flags: ignoreversion
Source: "Modules\*"; DestDir: "{app}\Modules"; Flags: ignoreversion recursesubdirs
Source: "Lib\*"; DestDir: "{app}\Lib"; Flags: ignoreversion recursesubdirs
Source: "Logs\*"; DestDir: "{app}\Logs"; Flags: ignoreversion recursesubdirs
Source: "ASCII-ART\*"; DestDir: "{app}\ASCII-ART"; Flags: ignoreversion recursesubdirs

[Icons]
Name: "{group}\Bockis System-Tool starten"; Filename: "powershell.exe"; Parameters: "-NoProfile -ExecutionPolicy Bypass -File \"{app}\Win_Gui_Module.ps1\""; WorkingDir: "{app}"; IconFilename: "powershell.exe"
Name: "{commondesktop}\Bockis System-Tool"; Filename: "powershell.exe"; Parameters: "-NoProfile -ExecutionPolicy Bypass -File \"{app}\Win_Gui_Module.ps1\""; WorkingDir: "{app}"; IconFilename: "powershell.exe"; Tasks: desktopicon

[Tasks]
Name: "desktopicon"; Description: "Desktop-Verknüpfung erstellen"; GroupDescription: "Zusätzliche Aufgaben:"

[Run]
Filename: "powershell.exe"; Parameters: "-NoProfile -ExecutionPolicy Bypass -File \"{app}\Win_Gui_Module.ps1\""; Description: "Bockis System-Tool jetzt starten"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
Type: filesandordersonly; Name: "{app}\Logs"
