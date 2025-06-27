; -- installer.iss für Bockis-Win_Gui --
[Setup]
AppName=Bockis System-Tool
AppVersion=3.1
AppPublisher=Bockis
AppPublisherURL=https://github.com/bockis
AppSupportURL=https://github.com/bockis
AppUpdatesURL=https://github.com/bockis
DefaultDirName={autopf}\Bockis-Win_Gui
DefaultGroupName=Bockis System-Tool
UninstallDisplayIcon={app}\IMG_0382.ico
OutputDir=.
OutputBaseFilename=Bockis-Win_Gui_Setup
SetupIconFile=IMG_0382.ico
WizardImageFile=Logo.bmp
WizardSmallImageFile=Logo.bmp
AppCopyright=© 2025 Bockis
LicenseFile=
InfoBeforeFile=
InfoAfterFile=
Compression=lzma
SolidCompression=yes
PrivilegesRequired=admin
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64

[Files]
Source: "Win_Gui_Module.ps1"; DestDir: "{app}"; Flags: ignoreversion
Source: "config.json"; DestDir: "{app}"; Flags: ignoreversion
Source: "README.md"; DestDir: "{app}"; Flags: ignoreversion
Source: "IMG_0382.ico"; DestDir: "{app}"; Flags: ignoreversion
Source: "IMG_0382.jpg"; DestDir: "{app}"; Flags: ignoreversion
Source: "Logo.bmp"; DestDir: "{app}"; Flags: ignoreversion

Source: "Modules\*"; DestDir: "{app}\Modules"; Flags: ignoreversion recursesubdirs
Source: "Lib\*"; DestDir: "{app}\Lib"; Flags: ignoreversion recursesubdirs
Source: "Logs\*"; DestDir: "{app}\Logs"; Flags: ignoreversion recursesubdirs
Source: "Examples\*"; DestDir: "{app}\Examples"; Flags: ignoreversion recursesubdirs

[Icons]
Name: "{group}\Bockis System-Tool starten"; Filename: "powershell.exe"; Parameters: "-WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass -File ""{app}\Win_Gui_Module.ps1"""; WorkingDir: "{app}"; IconFilename: "{app}\IMG_0382.ico"
Name: "{commondesktop}\Bockis System-Tool"; Filename: "powershell.exe"; Parameters: "-WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass -File ""{app}\Win_Gui_Module.ps1"""; WorkingDir: "{app}"; IconFilename: "{app}\IMG_0382.ico"; Tasks: desktopicon
Name: "{group}\Bockis System-Tool deinstallieren"; Filename: "{uninstallexe}"; IconFilename: "{app}\IMG_0382.ico"

[Tasks]
Name: "desktopicon"; Description: "Desktop-Verknüpfung erstellen"; GroupDescription: "Zusätzliche Aufgaben:"; Flags: unchecked

[Run]
Filename: "powershell.exe"; Parameters: "-WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass -File ""{app}\Win_Gui_Module.ps1"""; Description: "Bockis System-Tool jetzt starten"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
Type: filesandordirs; Name: "{app}\Logs"
