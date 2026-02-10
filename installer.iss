; ===================================================================
; INSTALLATIONS-SKRIPT FÜR BOCKIS SYSTEM-TOOL V4.1.2
; ===================================================================
;
; BESCHREIBUNG:
; -------------
; Dieses Inno Setup Skript erstellt einen professionellen Windows-
; Installer für das Bockis System-Tool - eine umfassende PowerShell-
; basierte GUI-Anwendung für Windows-Systemwartung, Diagnose und
; Optimierung.
;
; FUNKTIONSUMFANG DES TOOLS:
; ---------------------------
; • System- und Sicherheitstools (Aufgabenplanung, Netzwerk-Reset)
; • Diagnose & Reparatur (SFC, DISM, CHKDSK)
; • Netzwerk-Werkzeuge (Ping-Tests, Adapter-Neustart)
; • Bereinigungsfunktionen (Temp-Dateien, Caches, Logs)
; • Hardware-Monitoring (CPU, GPU, RAM, Temperaturen)
; • Integrierte Tool-Bibliothek mit 29 nützlichen System-Tools
; • System-Informationen und Status-Übersichten
;
; SYSTEMVORAUSSETZUNGEN:
; ----------------------
; • Windows 10 Build 17763 oder höher (empfohlen: Windows 11)
; • PowerShell 5.1 oder höher (automatische Prüfung)
; • .NET Framework 4.7.2 oder höher (empfohlen, nicht zwingend)
; • Administrator-Rechte für System-Tools erforderlich
; • Empfohlen: 4 GB RAM, 100 MB freier Speicherplatz
;
; INSTALLATIONS-FEATURES:
; -----------------------
; • Automatische Prüfung von PowerShell und .NET Framework
; • Code-Signierung für Setup.exe (optional, falls Zertifikat vorhanden)
; • Desktop- und Startmenü-Verknüpfungen
; • Vollständige Deinstallations-Routine mit Cleanup
; • LZMA2 Maximum-Kompression für kleinere Setup-Datei
;
; AUTOR: Bockis
; VERSION: 4.1.2
; ERSTELLT MIT: Inno Setup 6.x
; DATUM: 2025
; LIZENZ: Siehe LICENSE.txt
; ===================================================================

; -------------------------------------------------------------------
; ANWENDUNGS-DEFINITIONEN
; -------------------------------------------------------------------
#define MyAppName "Bockis System-Tool"
#define MyAppVersion "4.1.2"
#define MyAppPublisher "Bockis"
#define MyAppURL "https://github.com/bockis"
#define MyAppExeName "Win_Gui_Module.ps1"

[Setup]
; ===================================================================
; GRUNDLEGENDE INSTALLATIONS-KONFIGURATION
; ===================================================================

; -------------------------------------------------------------------
; Anwendungsinformationen
; -------------------------------------------------------------------
; Eindeutige GUID für diese Anwendung (bleibt bei Updates gleich)
AppId={{B0CK1-SY5T-T00L-4000-123456789ABC}}

; Anwendungsname und Versionsangaben
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion}
AppCopyright=© 2025 {#MyAppPublisher}

; Publisher-Informationen für Systemsteuerung
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}

; -------------------------------------------------------------------
; Installationsverzeichnisse und Startmenü
; -------------------------------------------------------------------
; Standard-Installationsort: C:\Program Files\Bockis-Win_Gui
DefaultDirName={autopf}\Bockis-Win_Gui

; Startmenü-Ordner: "Bockis System-Tool"
DefaultGroupName={#MyAppName}

; Benutzer darf "Kein Startmenü-Ordner" wählen
AllowNoIcons=yes

; Benutzer kann Installationsverzeichnis ändern
DisableDirPage=no

; Programmgruppen-Seite überspringen (einfachere Installation)
DisableProgramGroupPage=yes

; -------------------------------------------------------------------
; Setup-Ausgabe (generierte Dateien)
; -------------------------------------------------------------------
; Ausgabeverzeichnis: Gleiches Verzeichnis wie dieses Skript
OutputDir=.

; Name der Setup-Datei: Bockis-System-Tool-v4.0-Setup.exe
OutputBaseFilename=Bockis-System-Tool-v{#MyAppVersion}-Setup

; -------------------------------------------------------------------
; Visuelle Elemente und Benutzeroberfläche
; -------------------------------------------------------------------
; Icon für Setup.exe und Deinstallations-Eintrag
SetupIconFile=IMG_0382.ico
UninstallDisplayIcon={app}\IMG_0382.ico

; Wizard-Bilder für Installations-Assistent
; HINWEIS: Für optimale Darstellung ohne Verzerrung:
; - WizardImageFile: 164x314 px (moderner Wizard-Stil)
; - WizardSmallImageFile: 55x55 px (kleines Icon oben rechts)
; AKTUELL: Logo.bmp wird für beide verwendet - kann zu Verzerrung führen
; EMPFEHLUNG: Erstellen Sie zwei separate Dateien:
;   - Logo_Sidebar.bmp (164x314 px) für WizardImageFile
;   - Logo_Small.bmp (55x55 px) für WizardSmallImageFile
; ALTERNATIVE: Nur kleines Logo verwenden für cleanen Look:
;WizardImageFile=
WizardSmallImageFile=Logo.bmp

; Moderner Wizard-Stil (Windows 11 Design)
WizardStyle=modern

; Moderne Farbgebung (Dunkles Theme passend zur GUI)
WizardResizable=yes
WizardSizePercent=120

; Installations-Seiten aktivieren (informative Installation)
DisableWelcomePage=no
DisableReadyPage=no
DisableFinishedPage=no

; -------------------------------------------------------------------
; Deinstallations-Anzeige in Systemsteuerung
; -------------------------------------------------------------------
UninstallDisplayName={#MyAppName}

; -------------------------------------------------------------------
; Komprimierung (Maximale Kompression für kleinere Datei)
; -------------------------------------------------------------------
Compression=lzma2/max
SolidCompression=yes
LZMAUseSeparateProcess=yes
LZMANumBlockThreads=2

; -------------------------------------------------------------------
; Code-Signierung (Optional - benötigt Code-Signing-Zertifikat)
; -------------------------------------------------------------------
; Aktivieren Sie dies, wenn Sie ein Code-Signing-Zertifikat haben:
; SignTool=signtool sign /sha1 $qTHUMBPRINT$q /fd SHA256 /tr http://timestamp.digicert.com /td SHA256 $f
; SignToolRunMinimized=yes
;
; Ersetzen Sie THUMBPRINT mit dem Thumbprint Ihres Zertifikats.
; Beispiel: SignTool=signtool sign /sha1 $q1234567890ABCDEF1234567890ABCDEF12345678$q /fd SHA256 /tr http://timestamp.digicert.com /td SHA256 $f
;
; Alternativ: Signieren mit Zertifikat aus Speicher (automatisch)
; SignTool=signtool sign /n $qBocki Software$q /fd SHA256 /tr http://timestamp.digicert.com /td SHA256 $f
; SignToolRunMinimized=yes

; -------------------------------------------------------------------
; Sicherheit und Berechtigungen
; -------------------------------------------------------------------
; Administrator-Rechte erforderlich (für System-Tools notwendig)
PrivilegesRequired=admin

; Erlaubt Installation ohne Admin mit eingeschränkten Funktionen
PrivilegesRequiredOverridesAllowed=dialog

; -------------------------------------------------------------------
; Architektur-Unterstützung (64-Bit optimiert)
; -------------------------------------------------------------------
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible

; -------------------------------------------------------------------
; Versions-Informationen (in Setup.exe Eigenschaften sichtbar)
; -------------------------------------------------------------------
VersionInfoVersion={#MyAppVersion}
VersionInfoCompany={#MyAppPublisher}
VersionInfoDescription={#MyAppName} Installationsprogramm
VersionInfoCopyright=© 2025 {#MyAppPublisher}
VersionInfoProductName={#MyAppName}
VersionInfoProductVersion={#MyAppVersion}

; -------------------------------------------------------------------
; Mindestanforderungen
; -------------------------------------------------------------------
; Mindestens Windows 10 Build 17763 (Version 1809, Oktober 2018)
MinVersion=10.0.17763

; -------------------------------------------------------------------
; Anwendungsbehandlung während Installation
; -------------------------------------------------------------------
; Laufende Anwendungen vor Installation schließen
CloseApplications=yes

; Anwendungen nach Installation NICHT automatisch neu starten
RestartApplications=no

; -------------------------------------------------------------------
; Spracheinstellungen
; -------------------------------------------------------------------
; Kein Sprachdialog (nur Deutsch)
ShowLanguageDialog=no

[Languages]
; ===================================================================
; SPRACHKONFIGURATION
; ===================================================================
; Deutsche Sprache für alle Setup-Dialoge und Meldungen
Name: "german"; MessagesFile: "compiler:Languages\German.isl"

[Files]
; ===================================================================
; ZU INSTALLIERENDE DATEIEN
; ===================================================================

; -------------------------------------------------------------------
; Hauptanwendung (PowerShell-Skripte)
; -------------------------------------------------------------------
; Haupt-GUI-Modul (kritisch - immer überschreiben)
Source: "Win_Gui_Module.ps1"; DestDir: "{app}"; Flags: ignoreversion

; -------------------------------------------------------------------
; PowerShell-Module (Funktionsbibliotheken)
; -------------------------------------------------------------------
; Alle Module im Modules-Ordner installieren
Source: "Modules\*"; DestDir: "{app}\Modules"; Flags: ignoreversion recursesubdirs createallsubdirs

; -------------------------------------------------------------------
; Bibliotheken (C#-Erweiterungen für SQLite etc.)
; -------------------------------------------------------------------
; C#-Bibliotheken für erweiterte Funktionen
Source: "Lib\*"; DestDir: "{app}\Lib"; Flags: ignoreversion recursesubdirs createallsubdirs

; -------------------------------------------------------------------
; Grafiken und Icons
; -------------------------------------------------------------------
; Anwendungs-Icon
Source: "IMG_0382.ico"; DestDir: "{app}"; Flags: ignoreversion

; Logo für GUI
Source: "Logo.bmp"; DestDir: "{app}"; Flags: ignoreversion

; -------------------------------------------------------------------
; Konfiguration
; -------------------------------------------------------------------
; Konfigurationsdatei (nicht überschreiben bei Update)
Source: "config.json"; DestDir: "{app}"; Flags: onlyifdoesntexist

; -------------------------------------------------------------------
; Dokumentation und Lizenzen
; -------------------------------------------------------------------
; README mit Anleitung und Informationen
Source: "README.md"; DestDir: "{app}"; Flags: ignoreversion isreadme

; Software-Lizenz
Source: "LICENSE.txt"; DestDir: "{app}"; Flags: ignoreversion

; Lizenzen von Drittanbieter-Komponenten
Source: "THIRD-PARTY-LICENSES.md"; DestDir: "{app}"; Flags: ignoreversion

; -------------------------------------------------------------------
; Daten-Ordner (zentrale Speicherung aller Anwendungsdaten)
; -------------------------------------------------------------------
; HINWEIS: Ordner werden leer erstellt - Daten werden zur Laufzeit generiert
; Database-Ordner für SQLite-Datenbank
; Logs-Ordner für alle Log-Dateien
; ToolDownloads-Ordner für heruntergeladene Tools
; Temp-Ordner für temporäre Dateien


[Dirs]
; ===================================================================
; VERZEICHNISSE ERSTELLEN
; ===================================================================
; Zentrale Datenordner im Installationsverzeichnis
Name: "{app}\Data"; Permissions: users-modify
Name: "{app}\Data\Database"; Permissions: users-modify
Name: "{app}\Data\Logs"; Permissions: users-modify
Name: "{app}\Data\ToolDownloads"; Permissions: users-modify
Name: "{app}\Data\Temp"; Permissions: users-modify


[Icons]
; ===================================================================
; VERKNÜPFUNGEN (STARTMENÜ UND DESKTOP)
; ===================================================================

; -------------------------------------------------------------------
; Startmenü-Verknüpfungen
; -------------------------------------------------------------------
; Hauptverknüpfung: Startet das Tool mit PowerShell
Name: "{group}\{#MyAppName}"; Filename: "powershell.exe"; Parameters: "-WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass -File ""{app}\{#MyAppExeName}"""; IconFilename: "{app}\IMG_0382.ico"; Comment: "Windows System-Wartungstool mit GUI"

; README-Verknüpfung für Hilfe und Dokumentation
Name: "{group}\README anzeigen"; Filename: "{app}\README.md"; Comment: "Dokumentation und Nutzungshinweise"

; Deinstallations-Verknüpfung
Name: "{group}\{#MyAppName} deinstallieren"; Filename: "{uninstallexe}"; Comment: "Bockis System-Tool entfernen"

; -------------------------------------------------------------------
; Desktop-Verknüpfung (optional)
; -------------------------------------------------------------------
; Desktop-Icon (Benutzer wird während Installation gefragt)
Name: "{autodesktop}\{#MyAppName}"; Filename: "powershell.exe"; Parameters: "-WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass -File ""{app}\{#MyAppExeName}"""; IconFilename: "{app}\IMG_0382.ico"; Tasks: desktopicon; Comment: "Windows System-Wartungstool"

[Tasks]
; ===================================================================
; OPTIONALE AUFGABEN (Benutzerauswahl während Installation)
; ===================================================================

; -------------------------------------------------------------------
; Desktop-Verknüpfung erstellen (optional)
; -------------------------------------------------------------------
Name: "desktopicon"; Description: "Desktop-Verknüpfung erstellen"; GroupDescription: "Verknüpfungen:"

[Registry]
; ===================================================================
; REGISTRY-EINTRÄGE (für Dateizuordnungen etc.)
; ===================================================================

; -------------------------------------------------------------------
; Versionsinformationen speichern (für Update-Erkennung)
; -------------------------------------------------------------------
Root: HKCU; Subkey: "Software\Bockis\SystemTool"; ValueType: string; ValueName: "Version"; ValueData: "{#MyAppVersion}"; Flags: uninsdeletekey
Root: HKCU; Subkey: "Software\Bockis\SystemTool"; ValueType: string; ValueName: "InstallPath"; ValueData: "{app}"; Flags: uninsdeletekey
Root: HKCU; Subkey: "Software\Bockis\SystemTool"; ValueType: string; ValueName: "LastRun"; ValueData: "{code:GetCurrentDateTime}"; Flags: uninsdeletekey

[Code]

// Prüft, ob PowerShell installiert und verfügbar ist
function IsPowerShellInstalled: Boolean;
var
  PSPath: String;
begin
  // Suche nach PowerShell 5.1+ im System
  PSPath := ExpandConstant('{sys}\WindowsPowerShell\v1.0\powershell.exe');
  Result := FileExists(PSPath);
end;

// Prüft, ob .NET Framework 4.7.2 oder höher installiert ist
function IsDotNetInstalled: Boolean;
var
  Release: Cardinal;
begin
  // Registry-Schlüssel für .NET Framework Version auslesen
  // 461808 = .NET 4.7.2, 528040 = .NET 4.8
  if RegQueryDWordValue(HKLM, 'SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full', 'Release', Release) then
    Result := (Release >= 461808)  // .NET 4.7.2 oder höher
  else
    Result := False;
end;

// Sucht nach "Bockis" im DisplayName aller Uninstall-Einträge
function FindBockisToolUninstallKey(var FoundVersion: String; var DebugInfo: String): String;
var
  BaseKey: String;
  SubKeyNames: TArrayOfString;
  I: Integer;
  DisplayName: String;
  DisplayNameLower: String;
  KeysChecked: Integer;
begin
  Result := '';
  FoundVersion := '';
  KeysChecked := 0;
  DebugInfo := '';
  
  // HKCU 32-Bit Uninstall durchsuchen
  BaseKey := 'Software\Microsoft\Windows\CurrentVersion\Uninstall';
  if RegGetSubkeyNames(HKCU, BaseKey, SubKeyNames) then
  begin
    DebugInfo := DebugInfo + 'HKCU Keys: ' + IntToStr(GetArrayLength(SubKeyNames)) + #13#10;
    for I := 0 to GetArrayLength(SubKeyNames) - 1 do
    begin
      KeysChecked := KeysChecked + 1;
      if RegQueryStringValue(HKCU, BaseKey + '\' + SubKeyNames[I], 'DisplayName', DisplayName) then
      begin
        DisplayNameLower := Lowercase(DisplayName);
        // Debug: Alle Bockis-bezogenen Apps loggen
        if Pos('bockis', DisplayNameLower) > 0 then
          DebugInfo := DebugInfo + '  Found: ' + DisplayName + #13#10;
        
        if (Pos('bockis', DisplayNameLower) > 0) and (Pos('system', DisplayNameLower) > 0) then
        begin
          Result := BaseKey + '\' + SubKeyNames[I];
          if not RegQueryStringValue(HKCU, Result, 'DisplayVersion', FoundVersion) then
            FoundVersion := 'unknown';
          Exit;
        end;
      end;
    end;
  end
  else
    DebugInfo := DebugInfo + 'HKCU: Keine Keys gefunden' + #13#10;
  
  // HKLM 32-Bit Uninstall durchsuchen
  if RegGetSubkeyNames(HKLM, BaseKey, SubKeyNames) then
  begin
    DebugInfo := DebugInfo + 'HKLM Keys: ' + IntToStr(GetArrayLength(SubKeyNames)) + #13#10;
    for I := 0 to GetArrayLength(SubKeyNames) - 1 do
    begin
      KeysChecked := KeysChecked + 1;
      if RegQueryStringValue(HKLM, BaseKey + '\' + SubKeyNames[I], 'DisplayName', DisplayName) then
      begin
        DisplayNameLower := Lowercase(DisplayName);
        if Pos('bockis', DisplayNameLower) > 0 then
          DebugInfo := DebugInfo + '  Found: ' + DisplayName + #13#10;
        
        if (Pos('bockis', DisplayNameLower) > 0) and (Pos('system', DisplayNameLower) > 0) then
        begin
          Result := BaseKey + '\' + SubKeyNames[I];
          if not RegQueryStringValue(HKLM, Result, 'DisplayVersion', FoundVersion) then
            FoundVersion := 'unknown';
          Exit;
        end;
      end;
    end;
  end
  else
    DebugInfo := DebugInfo + 'HKLM: Keine Keys gefunden' + #13#10;
  
  // HKLM 64-Bit Uninstall durchsuchen (Wow6432Node)
  BaseKey := 'Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall';
  if RegGetSubkeyNames(HKLM, BaseKey, SubKeyNames) then
  begin
    DebugInfo := DebugInfo + 'HKLM64 Keys: ' + IntToStr(GetArrayLength(SubKeyNames)) + #13#10;
    for I := 0 to GetArrayLength(SubKeyNames) - 1 do
    begin
      KeysChecked := KeysChecked + 1;
      if RegQueryStringValue(HKLM, BaseKey + '\' + SubKeyNames[I], 'DisplayName', DisplayName) then
      begin
        DisplayNameLower := Lowercase(DisplayName);
        if Pos('bockis', DisplayNameLower) > 0 then
          DebugInfo := DebugInfo + '  Found: ' + DisplayName + #13#10;
        
        if (Pos('bockis', DisplayNameLower) > 0) and (Pos('system', DisplayNameLower) > 0) then
        begin
          Result := BaseKey + '\' + SubKeyNames[I];
          if not RegQueryStringValue(HKLM, Result, 'DisplayVersion', FoundVersion) then
            FoundVersion := 'unknown';
          Exit;
        end;
      end;
    end;
  end
  else
    DebugInfo := DebugInfo + 'HKLM64: Keine Keys gefunden' + #13#10;
  
  DebugInfo := DebugInfo + 'Total Keys checked: ' + IntToStr(KeysChecked);
end;

// Liest installierte Version aus Registry (prüft mehrere Quellen, bevorzugt Uninstall)
function GetInstalledVersion(var DebugInfo: String): String;
var
  UninstallKey: String;
  FoundVersion: String;
  OwnRegVersion: String;
begin
  Result := '';
  DebugInfo := '';
  
  // Uninstall-Key durch Klartext-Suche finden (ZUERST, um alte Versionen zu finden)
  UninstallKey := FindBockisToolUninstallKey(FoundVersion, DebugInfo);
  if UninstallKey <> '' then
  begin
    Result := FoundVersion;
    DebugInfo := 'Version aus Uninstall: ' + UninstallKey + #13#10 + DebugInfo;
    Exit;
  end;
  
  // Wenn nichts in Uninstall gefunden, dann eigenen Registry-Schlüssel prüfen
  if RegQueryStringValue(HKCU, 'Software\Bockis\SystemTool', 'Version', OwnRegVersion) then
  begin
    Result := OwnRegVersion;
    DebugInfo := 'Version aus HKCU\Software\Bockis\SystemTool (keine Uninstall-Info gefunden)';
    Exit;
  end;
end;

// Prüft ob irgendeine Version installiert ist
function IsAnyVersionInstalled: Boolean;
var
  UninstallKey: String;
  DummyVersion: String;
  DummyDebug: String;
begin
  Result := False;
  
  // Prüfe ob Installationsverzeichnis existiert
  if DirExists(ExpandConstant('{autopf}\Bockis-Win_Gui')) then
  begin
    Result := True;
    Exit;
  end;
  
  // Suche nach Uninstall-Eintrag mit "Bockis System-Tool"
  UninstallKey := FindBockisToolUninstallKey(DummyVersion, DummyDebug);
  if UninstallKey <> '' then
  begin
    Result := True;
    Exit;
  end;
end;

// Vergleicht zwei Versionen (gibt -1, 0 oder 1 zurück)
function CompareVersion(V1, V2: String): Integer;
var
  P, N1, N2: Integer;
begin
  Result := 0;
  while (Result = 0) and ((V1 <> '') or (V2 <> '')) do
  begin
    P := Pos('.', V1);
    if P > 0 then
    begin
      N1 := StrToIntDef(Copy(V1, 1, P - 1), 0);
      Delete(V1, 1, P);
    end
    else if V1 <> '' then
    begin
      N1 := StrToIntDef(V1, 0);
      V1 := '';
    end
    else
      N1 := 0;

    P := Pos('.', V2);
    if P > 0 then
    begin
      N2 := StrToIntDef(Copy(V2, 1, P - 1), 0);
      Delete(V2, 1, P);
    end
    else if V2 <> '' then
    begin
      N2 := StrToIntDef(V2, 0);
      V2 := '';
    end
    else
      N2 := 0;

    if N1 < N2 then
      Result := -1
    else if N1 > N2 then
      Result := 1;
  end;
end;

// Prüft ob eine ältere Version installiert ist
function IsOlderVersionInstalled: Boolean;
var
  InstalledVersion: String;
  DummyDebug: String;
begin
  InstalledVersion := GetInstalledVersion(DummyDebug);
  
  // Wenn keine Version gefunden aber Installation existiert -> als älter behandeln
  if (InstalledVersion = '') and IsAnyVersionInstalled then
  begin
    Result := True;
    Exit;
  end;
  
  // Versions-Vergleich: -1 = älter, 0 = gleich, 1 = neuer
  Result := (InstalledVersion <> '') and (CompareVersion(InstalledVersion, '{#MyAppVersion}') < 0);
end;

// Prüft ob eine neuere Version installiert ist
function IsNewerVersionInstalled: Boolean;
var
  InstalledVersion: String;
  DummyDebug: String;
begin
  InstalledVersion := GetInstalledVersion(DummyDebug);
  // Versions-Vergleich: 1 = neuer
  Result := (InstalledVersion <> '') and (CompareVersion(InstalledVersion, '{#MyAppVersion}') > 0);
end;

// Prüft ob das Tool gerade läuft
function IsAppRunning: Boolean;
var
  ResultCode: Integer;
begin
  Result := False;
  // Prüft ob PowerShell-Prozess mit Win_Gui_Module.ps1 läuft
  if Exec('powershell.exe',
          '-NoProfile -Command "if (Get-Process powershell -ErrorAction SilentlyContinue | Where-Object {$_.CommandLine -like ''*Win_Gui_Module.ps1*''}) { exit 1 } else { exit 0 }"',
          '', SW_HIDE, ewWaitUntilTerminated, ResultCode) then
  begin
    Result := (ResultCode = 1);
  end;
end;

// Beendet laufende Instanz des Tools
procedure CloseRunningApp;
var
  ResultCode: Integer;
begin
  // Beendet alle PowerShell-Prozesse die Win_Gui_Module.ps1 ausführen
  Exec('powershell.exe',
       '-NoProfile -Command "Get-Process powershell -ErrorAction SilentlyContinue | Where-Object {$_.CommandLine -like ''*Win_Gui_Module.ps1*''} | Stop-Process -Force"',
       '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
  Sleep(1000); // 1 Sekunde warten
end;

// Deinstalliert alte Version über Uninstall-String
function UninstallOldVersion: Boolean;
var
  UninstallKey: String;
  UninstallString: String;
  FoundVersion: String;
  DebugInfo: String;
  ResultCode: Integer;
begin
  Result := False;
  
  // Finde Uninstall-Key der alten Version
  UninstallKey := FindBockisToolUninstallKey(FoundVersion, DebugInfo);
  
  if UninstallKey = '' then
    Exit;
  
  // Lese UninstallString aus
  if RegQueryStringValue(HKCU, UninstallKey, 'UninstallString', UninstallString) or
     RegQueryStringValue(HKLM, UninstallKey, 'UninstallString', UninstallString) then
  begin
    // QuietUninstallString bevorzugen (stille Deinstallation)
    if not (RegQueryStringValue(HKCU, UninstallKey, 'QuietUninstallString', UninstallString) or
            RegQueryStringValue(HKLM, UninstallKey, 'QuietUninstallString', UninstallString)) then
    begin
      // Füge /SILENT Parameter für Inno Setup Uninstaller hinzu
      if Pos('unins', Lowercase(UninstallString)) > 0 then
        UninstallString := UninstallString + ' /SILENT /NORESTART';
    end;
    
    // Führe Deinstallation aus
    if Exec('cmd.exe', '/C "' + UninstallString + '"', '', SW_HIDE, ewWaitUntilTerminated, ResultCode) then
    begin
      // Warte bis Deinstallation abgeschlossen ist
      Sleep(3000);
      Result := True;
    end;
  end;
end;



// Wird vor dem Installations-Wizard aufgerufen - prüft Systemvoraussetzungen
function InitializeSetup(): Boolean;
var
  InstalledVersion: String;
  InstallDir: String;
  DebugMsg: String;
begin
  Result := True;
  
  // DEBUG: Prüfe was erkannt wird
  DebugMsg := 'DEBUG-INFO:' + #13#10 + #13#10;
  
  if DirExists(ExpandConstant('{autopf}\Bockis-Win_Gui')) then
    DebugMsg := DebugMsg + '✓ Verzeichnis gefunden: C:\Program Files\Bockis-Win_Gui' + #13#10
  else
    DebugMsg := DebugMsg + '✗ Verzeichnis nicht gefunden' + #13#10;
  
  DebugMsg := DebugMsg + #13#10;
  
  InstalledVersion := GetInstalledVersion(InstallDir);
  if InstalledVersion <> '' then
    DebugMsg := DebugMsg + '✓ Version erkannt: ' + InstalledVersion + #13#10 + InstallDir + #13#10
  else
    DebugMsg := DebugMsg + '✗ Keine Version in Registry' + #13#10 + InstallDir + #13#10;
  
  DebugMsg := DebugMsg + #13#10;
  
  if IsAnyVersionInstalled then
    DebugMsg := DebugMsg + '✓ Installation erkannt' + #13#10
  else
    DebugMsg := DebugMsg + '✗ Keine Installation erkannt' + #13#10;
  
  // DEBUG-Ausgabe anzeigen (kann später entfernt werden)
  MsgBox(DebugMsg, mbInformation, MB_OK);
  
  // PowerShell-Verfügbarkeit prüfen (KRITISCH)
  if not IsPowerShellInstalled then
  begin
    MsgBox('PowerShell wurde nicht gefunden!' + #13#10 + #13#10 +
           'Bockis System-Tool benötigt PowerShell 5.1 oder höher.' + #13#10 +
           'Bitte installieren Sie PowerShell und starten Sie die Installation erneut.' + #13#10 + #13#10 +
           'Die Installation wird abgebrochen.', 
           mbError, MB_OK);
    Result := False;
    Exit;
  end;
  
  // .NET Framework prüfen (EMPFOHLEN, nicht kritisch)
  if not IsDotNetInstalled then
  begin
    if MsgBox('.NET Framework 4.7.2 oder höher wurde nicht gefunden.' + #13#10 + #13#10 +
              'Einige Funktionen (z.B. SQLite-Datenbank) sind möglicherweise eingeschränkt.' + #13#10 +
              'Es wird empfohlen, .NET Framework 4.8 zu installieren.' + #13#10 + #13#10 +
              'Möchten Sie die Installation trotzdem fortsetzen?', 
              mbConfirmation, MB_YESNO) = IDNO then
    begin
      Result := False;
      Exit;
    end;
  end;
  
  // Prüfen ob neuere Version bereits installiert ist
  if IsNewerVersionInstalled then
  begin
    InstalledVersion := GetInstalledVersion(InstallDir);
    MsgBox('ACHTUNG: Downgrade erkannt!' + #13#10 + #13#10 +
           'Installierte Version: ' + InstalledVersion + #13#10 +
           'Setup-Version: {#MyAppVersion}' + #13#10 + #13#10 +
           'Sie versuchen eine ältere Version über eine neuere zu installieren.' + #13#10 +
           'Dies wird nicht empfohlen!' + #13#10 + #13#10 +
           'Die Installation wird abgebrochen.',
           mbError, MB_OK);
    Result := False;
    Exit;
  end;
  
  // Info über Update wenn ältere Version gefunden
  if IsOlderVersionInstalled then
  begin
    InstalledVersion := GetInstalledVersion(InstallDir);
    
    // Wenn keine Version erkannt wurde, aber Installation existiert
    if InstalledVersion = '' then
      InstalledVersion := 'unbekannt (älter als 4.0)';
    
    if MsgBox('UPDATE VERFÜGBAR' + #13#10 + #13#10 +
              'Installierte Version: ' + InstalledVersion + #13#10 +
              'Neue Version: {#MyAppVersion}' + #13#10 + #13#10 +
              'Die alte Version wird automatisch deinstalliert.' + #13#10 +
              'Alle Einstellungen bleiben erhalten.' + #13#10 + #13#10 +
              'Möchten Sie das Update durchführen?',
              mbInformation, MB_YESNO) = IDNO then
    begin
      Result := False;
      Exit;
    end;
    
    // Alte Version deinstallieren
    if UninstallOldVersion then
    begin
      MsgBox('Alte Version wurde erfolgreich deinstalliert.' + #13#10 +
             'Die Installation wird nun fortgesetzt.',
             mbInformation, MB_OK);
    end
    else
    begin
      if MsgBox('Die alte Version konnte nicht automatisch deinstalliert werden.' + #13#10 + #13#10 +
                'Möchten Sie die Installation trotzdem fortsetzen?' + #13#10 +
                '(Es wird über die alte Version installiert)',
                mbConfirmation, MB_YESNO) = IDNO then
      begin
        Result := False;
        Exit;
      end;
    end;
  end;
  
  // Prüfen ob Tool läuft
  if IsAppRunning then
  begin
    if MsgBox('Das Bockis System-Tool läuft gerade!' + #13#10 + #13#10 +
              'Die Anwendung muss vor der Installation geschlossen werden.' + #13#10 + #13#10 +
              'Soll die Anwendung jetzt automatisch beendet werden?',
              mbConfirmation, MB_YESNO) = IDYES then
    begin
      CloseRunningApp;
      // Nochmal prüfen
      if IsAppRunning then
      begin
        MsgBox('Die Anwendung konnte nicht beendet werden.' + #13#10 +
               'Bitte schließen Sie das Tool manuell und starten Sie die Installation erneut.',
               mbError, MB_OK);
        Result := False;
        Exit;
      end;
    end
    else
    begin
      Result := False;
      Exit;
    end;
  end;
end;

// Wird bei jedem Schritt der Installation aufgerufen
procedure CurStepChanged(CurStep: TSetupStep);
begin
  // Keine Post-Installation Tasks
end;

// Gibt das aktuelle Datum und die Uhrzeit zurück (für Registry)
function GetCurrentDateTime(Param: String): String;
begin
  Result := GetDateTimeString('yyyy-mm-dd hh:nn:ss', '-', ':');
end;

[CustomMessages]
; ===================================================================
; BENUTZERDEFINIERTE MELDUNGEN (Deutsch)
; ===================================================================
german.AppName=Bockis System-Tool
german.SetupWindowTitle=Installation - Bockis System-Tool
german.UninstallAppTitle=Deinstallation - Bockis System-Tool
german.LaunchProgram={#MyAppName} jetzt starten

; Moderne, übersichtliche Willkommensnachricht
german.WelcomeLabel2=Willkommen zur Installation von%n%n{#MyAppName} v{#MyAppVersion}%n%n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%n%nProfessionelles Windows System-Wartungstool%nmit moderner GUI und umfangreichen Funktionen:%n%n  ✓  System-Reparatur & Diagnose%n  ✓  Echtzeit Hardware-Monitoring%n  ✓  Netzwerk-Tools & Optimierung%n  ✓  Intelligente Bereinigung%n  ✓  29+ integrierte Wartungstools%n%n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%n%nBitte schließen Sie alle laufenden Anwendungen%nund klicken Sie auf "Weiter" zum Fortfahren.

[Run]
; ===================================================================
; NACH-INSTALLATIONS-AKTIONEN
; ===================================================================

; -------------------------------------------------------------------
; PawnIO Ring-0 Treiber über WinGet installieren (kritisch für Hardware-Monitoring)
; -------------------------------------------------------------------
; WICHTIG: PawnIO ist der sichere Kernel-Treiber für Hardware-Zugriff!
; LibreHardwareMonitorLib.dll ist bereits im Lib-Ordner enthalten und
; benötigt PawnIO für sicheren Ring-0 Zugriff.
; OHNE PawnIO funktioniert Hardware-Monitoring NICHT!
Filename: "{sys}\WindowsPowerShell\v1.0\powershell.exe"; Parameters: "-NoProfile -ExecutionPolicy Bypass -Command ""& {{ try {{ $null = Get-Command winget -ErrorAction Stop; Write-Host 'Installiere PawnIO-Treiber...'; winget install --id namazso.PawnIO --exact --silent --accept-source-agreements --accept-package-agreements | Out-Null; if ($LASTEXITCODE -eq 0 -or $LASTEXITCODE -eq -1978335189) {{ Write-Host 'PawnIO-Treiber installiert! Neustart erforderlich!' -ForegroundColor Green }} else {{ Write-Warning 'Installation fehlgeschlagen (Code: $LASTEXITCODE)' }} }} catch {{ Write-Warning 'WinGet nicht verfuegbar - Hardware-Monitoring wird NICHT funktionieren' }} }}"""; Description: "PawnIO Ring-0 Treiber installieren (ERFORDERLICH für Hardware-Monitoring)"; StatusMsg: "Installiere PawnIO-Treiber via WinGet..."; Flags: runhidden

; -------------------------------------------------------------------
; Anwendung nach Installation starten (optional)
; -------------------------------------------------------------------
Filename: "powershell.exe"; Parameters: "-WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass -File ""{app}\{#MyAppExeName}"""; Description: "{cm:LaunchProgram,{#MyAppName}}"; Flags: nowait postinstall skipifsilent unchecked

; -------------------------------------------------------------------
; README anzeigen nach Installation (optional)
; -------------------------------------------------------------------
Filename: "{app}\README.md"; Description: "README-Datei anzeigen"; Flags: postinstall shellexec skipifsilent unchecked

[UninstallDelete]
; ===================================================================
; BEIM DEINSTALLIEREN ZU LÖSCHENDE DATEIEN
; ===================================================================
; WICHTIG: Alle Daten werden jetzt zentral im Data-Ordner gespeichert!
; Der Deinstaller muss nur noch das Installations-Verzeichnis löschen.

; -------------------------------------------------------------------
; Zentrale Daten-Ordner löschen
; -------------------------------------------------------------------
Type: filesandordirs; Name: "{app}\Data"

; -------------------------------------------------------------------
; Temporäre Dateien und alte Logs löschen
; -------------------------------------------------------------------
Type: files; Name: "{app}\*.tmp"
Type: files; Name: "{app}\*.log"

; -------------------------------------------------------------------
; Archiv-Ordner löschen (alte Backups, falls vorhanden)
; -------------------------------------------------------------------
Type: filesandordirs; Name: "{app}\_Archive"

[UninstallRun]
; ===================================================================
; BEIM DEINSTALLIEREN AUSZUFÜHRENDE BEFEHLE
; ===================================================================

; -------------------------------------------------------------------
; Registry-Einträge löschen (zusätzliche Sicherheit)
; -------------------------------------------------------------------
Filename: "reg.exe"; Parameters: "delete ""HKCU\Software\Bockis\SystemTool"" /f"; Flags: runhidden; RunOnceId: "CleanupRegistry"
