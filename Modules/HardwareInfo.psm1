# HardwareInfo.psm1 - Modul für Hardware-Informationen
function Get-CPUInfo {
    param (
        [System.Windows.Forms.RichTextBox]$infoBox
    )
    
    $infoBox.Clear()
    $infoBox.SelectionColor = [System.Drawing.Color]::DarkBlue
    $infoBox.AppendText("===== CPU-INFORMATIONEN =====`r`n`r`n")
    
    try {
        $cpuInfo = Get-WmiObject -Class Win32_Processor
        foreach ($cpu in $cpuInfo) {
            $infoBox.SelectionColor = [System.Drawing.Color]::Blue
            $infoBox.AppendText("PROZESSOR-DETAILS:`r`n")
            $infoBox.SelectionColor = [System.Drawing.Color]::Black
            
            $infoBox.AppendText("Prozessor: $($cpu.Name)`r`n")
            $infoBox.AppendText("Hersteller: $($cpu.Manufacturer)`r`n")
            $infoBox.AppendText("Kerne: $($cpu.NumberOfCores)`r`n")
            $infoBox.AppendText("Logische Prozessoren: $($cpu.NumberOfLogicalProcessors)`r`n")
            $infoBox.AppendText("Taktrate: $($cpu.MaxClockSpeed) MHz`r`n")
            
            # L2-Cache anzeigen (wenn verfügbar)
            if ($cpu.L2CacheSize -gt 0) {
                $l2CacheMB = $cpu.L2CacheSize / 1024
                $infoBox.AppendText("L2-Cache: $($l2CacheMB.ToString('F2')) MB`r`n")
            }
            else {
                $infoBox.AppendText("L2-Cache: Nicht verfügbar`r`n")
            }
            
            # L3-Cache anzeigen (wenn verfügbar)
            if ($cpu.L3CacheSize -gt 0) {
                $l3CacheMB = $cpu.L3CacheSize / 1024
                $infoBox.AppendText("L3-Cache: $($l3CacheMB.ToString('F2')) MB`r`n")
            }
            else {
                $infoBox.AppendText("L3-Cache: Nicht verfügbar`r`n")
            }
        }
    }
    catch {
        $infoBox.SelectionColor = [System.Drawing.Color]::Red
        $infoBox.AppendText("Fehler beim Abrufen der CPU-Informationen: $_`r`n")
    }
}

function Get-RAMInfo {
    param (
        [System.Windows.Forms.RichTextBox]$infoBox
    )
    
    $infoBox.Clear()
    $infoBox.SelectionColor = [System.Drawing.Color]::DarkBlue
    $infoBox.AppendText("===== RAM-INFORMATIONEN =====`r`n`r`n")
    
    try {
        # Gesamter Arbeitsspeicher
        $totalRAM = (Get-WmiObject -Class Win32_ComputerSystem).TotalPhysicalMemory / 1GB
        
        $infoBox.SelectionColor = [System.Drawing.Color]::Blue
        $infoBox.AppendText("SPEICHER-ÜBERSICHT:`r`n")
        $infoBox.SelectionColor = [System.Drawing.Color]::Black
        
        $infoBox.AppendText("Gesamter RAM: $([math]::Round($totalRAM, 2)) GB`r`n")
        
        # Speicherauslastung
        $osInfo = Get-WmiObject -Class Win32_OperatingSystem
        $freeRAM = $osInfo.FreePhysicalMemory / 1MB
        $usedRAM = $totalRAM - $freeRAM
        $ramUsagePercent = ($usedRAM / $totalRAM) * 100
        
        $infoBox.AppendText("Verwendeter RAM: $([math]::Round($usedRAM, 2)) GB ($([math]::Round($ramUsagePercent, 1))%)`r`n")
        $infoBox.AppendText("Freier RAM: $([math]::Round($freeRAM, 2)) GB`r`n`r`n")
        
        # RAM-Module Details
        $infoBox.SelectionColor = [System.Drawing.Color]::Blue
        $infoBox.AppendText("RAM-MODULE:`r`n")
        $infoBox.SelectionColor = [System.Drawing.Color]::Black
        
        $memoryModules = Get-WmiObject -Class Win32_PhysicalMemory
        $infoBox.AppendText("Anzahl der RAM-Module: $($memoryModules.Count)`r`n`r`n")
        
        $moduleIndex = 1
        foreach ($module in $memoryModules) {
            $capacity = $module.Capacity / 1GB
            $infoBox.SelectionColor = [System.Drawing.Color]::Blue
            $infoBox.AppendText("Modul $moduleIndex Details:`r`n")
            $infoBox.SelectionColor = [System.Drawing.Color]::Black
            $infoBox.AppendText("  Kapazität: $([math]::Round($capacity, 2)) GB`r`n")
            $infoBox.AppendText("  Eingebaut in: $($module.DeviceLocator)`r`n")
            $infoBox.AppendText("  Hersteller: $($module.Manufacturer)`r`n")
            $infoBox.AppendText("  Taktrate: $($module.Speed) MHz`r`n")
            $moduleIndex++
        }
    }
    catch {
        $infoBox.SelectionColor = [System.Drawing.Color]::Red
        $infoBox.AppendText("Fehler beim Abrufen der RAM-Informationen: $_`r`n")
    }
}

function Get-GPUInfo {
    param (
        [System.Windows.Forms.RichTextBox]$infoBox
    )
    
    $infoBox.Clear()
    $infoBox.SelectionColor = [System.Drawing.Color]::DarkBlue
    $infoBox.AppendText("===== GRAFIKKARTEN-INFORMATIONEN =====`r`n`r`n")
    
    try {
        $gpuInfo = Get-WmiObject -Class Win32_VideoController
        $gpuIndex = 1
        
        foreach ($gpu in $gpuInfo) {
            $infoBox.SelectionColor = [System.Drawing.Color]::Blue
            $infoBox.AppendText("GRAFIKKARTE ${gpuIndex}:`r`n")
            $infoBox.SelectionColor = [System.Drawing.Color]::Black
            
            # Basisinformationen
            $infoBox.AppendText("Name: $($gpu.Name)`r`n")
            $infoBox.AppendText("Hersteller: $($gpu.AdapterCompatibility)`r`n")
            $infoBox.AppendText("Treiber-Version: $($gpu.DriverVersion)`r`n")
            
            # Speicher
            if ($gpu.AdapterRAM) {
                $vramMB = $gpu.AdapterRAM / 1MB
                $infoBox.AppendText("Video-RAM: $([math]::Round($vramMB, 0)) MB`r`n")
            }
            else {
                $infoBox.AppendText("Video-RAM: Nicht verfügbar`r`n")
            }
            
            # Aktuelle Einstellungen
            $infoBox.AppendText("`r`nAKTUELLER ANZEIGEMODUS:`r`n")
            $infoBox.AppendText("Auflösung: $($gpu.CurrentHorizontalResolution) x $($gpu.CurrentVerticalResolution)`r`n")
            $infoBox.AppendText("Farbtiefe: $($gpu.CurrentBitsPerPixel) Bits pro Pixel`r`n")
            $infoBox.AppendText("Aktualisierungsrate: $($gpu.CurrentRefreshRate) Hz`r`n")
            
            $gpuIndex++
        }
    }
    catch {
        $infoBox.SelectionColor = [System.Drawing.Color]::Red
        $infoBox.AppendText("Fehler beim Abrufen der Grafikkarten-Informationen: $_`r`n")
    }
}

function Get-DiskInfo {
    param (
        [System.Windows.Forms.RichTextBox]$infoBox
    )
    
    $infoBox.Clear()
    $infoBox.SelectionColor = [System.Drawing.Color]::DarkBlue
    $infoBox.AppendText("===== FESTPLATTEN-INFORMATIONEN =====`r`n`r`n")
    
    try {
        # Physische Laufwerke
        $infoBox.SelectionColor = [System.Drawing.Color]::Blue
        $infoBox.AppendText("PHYSISCHE FESTPLATTEN:`r`n")
        $infoBox.SelectionColor = [System.Drawing.Color]::Black
        
        $drives = Get-WmiObject -Class Win32_DiskDrive
        $driveIndex = 1
        
        foreach ($drive in $drives) {
            $sizeGB = [math]::Round($drive.Size / 1GB, 2)
            
            $infoBox.SelectionColor = [System.Drawing.Color]::Blue
            $infoBox.AppendText("`r`nFESTPLATTE $driveIndex - $($drive.Model):`r`n")
            $infoBox.SelectionColor = [System.Drawing.Color]::Black
            
            $infoBox.AppendText("Modell: $($drive.Model)`r`n")
            $infoBox.AppendText("Größe: $sizeGB GB`r`n")
            $infoBox.AppendText("Schnittstelle: $($drive.InterfaceType)`r`n")
            
            $driveIndex++
        }
        
        # Logische Laufwerke
        $infoBox.AppendText("`r`n")
        $infoBox.SelectionColor = [System.Drawing.Color]::Blue
        $infoBox.AppendText("LOGISCHE LAUFWERKE:`r`n")
        $infoBox.SelectionColor = [System.Drawing.Color]::Black
        
        $logicalDrives = Get-WmiObject -Class Win32_LogicalDisk -Filter "DriveType=3"
        
        foreach ($logicalDrive in $logicalDrives) {
            $freeGB = [math]::Round($logicalDrive.FreeSpace / 1GB, 2)
            $sizeGB = [math]::Round($logicalDrive.Size / 1GB, 2)
            $usedPercent = [math]::Round(($logicalDrive.Size - $logicalDrive.FreeSpace) / $logicalDrive.Size * 100, 1)
            
            $infoBox.SelectionColor = [System.Drawing.Color]::Blue
            $infoBox.AppendText("`r`nLAUFWERK $($logicalDrive.DeviceID):`r`n")
            $infoBox.SelectionColor = [System.Drawing.Color]::Black
            
            $infoBox.AppendText("Bezeichnung: $($logicalDrive.VolumeName)`r`n")
            $infoBox.AppendText("Dateisystem: $($logicalDrive.FileSystem)`r`n")
            $infoBox.AppendText("Gesamtgröße: $sizeGB GB`r`n")
            $infoBox.AppendText("Freier Speicher: $freeGB GB`r`n")
            
            $infoBox.AppendText("Belegung: ")
            if ($usedPercent -gt 90) {
                $infoBox.SelectionColor = [System.Drawing.Color]::Red
                $infoBox.AppendText("$usedPercent% (Kritisch!)`r`n")
            }
            elseif ($usedPercent -gt 75) {
                $infoBox.SelectionColor = [System.Drawing.Color]::Orange
                $infoBox.AppendText("$usedPercent% (Warnung)`r`n")
            }
            else {
                $infoBox.SelectionColor = [System.Drawing.Color]::Green
                $infoBox.AppendText("$usedPercent% (OK)`r`n")
            }
        }
    }
    catch {
        $infoBox.SelectionColor = [System.Drawing.Color]::Red
        $infoBox.AppendText("Fehler beim Abrufen der Festplatten-Informationen: $_`r`n")
    }
}

function Get-NetworkInfo {
    param (
        [System.Windows.Forms.RichTextBox]$infoBox
    )
    
    $infoBox.Clear()
    $infoBox.SelectionColor = [System.Drawing.Color]::DarkBlue
    $infoBox.AppendText("===== NETZWERK-INFORMATIONEN =====`r`n`r`n")
    
    try {
        # Netzwerkadapter
        $infoBox.SelectionColor = [System.Drawing.Color]::Blue
        $infoBox.AppendText("NETZWERKADAPTER:`r`n")
        $infoBox.SelectionColor = [System.Drawing.Color]::Black
        
        $networkAdapters = Get-WmiObject -Class Win32_NetworkAdapter | Where-Object { $_.PhysicalAdapter -eq $true }
        $adapterIndex = 1
        
        foreach ($adapter in $networkAdapters) {
            $infoBox.SelectionColor = [System.Drawing.Color]::Blue
            $infoBox.AppendText("`r`nADAPTER $adapterIndex - $($adapter.Name):`r`n")
            $infoBox.SelectionColor = [System.Drawing.Color]::Black
            
            $infoBox.AppendText("Name: $($adapter.Name)`r`n")
            $infoBox.AppendText("Hersteller: $($adapter.Manufacturer)`r`n")
            $infoBox.AppendText("Adapter-Typ: $($adapter.AdapterType)`r`n")
            $infoBox.AppendText("MAC-Adresse: $($adapter.MACAddress)`r`n")
            
            # Geschwindigkeit anzeigen (wenn verfügbar)
            if ($adapter.Speed) {
                $speedMbps = $adapter.Speed / 1000000
                $infoBox.AppendText("Geschwindigkeit: $speedMbps Mbit/s`r`n")
            }
            else {
                $infoBox.AppendText("Geschwindigkeit: Nicht verfügbar`r`n")
            }
            
            # Verbindungsstatus anzeigen
            if ($adapter.NetConnectionStatus -eq 2) {
                $infoBox.AppendText("Status: Verbunden`r`n")
            }
            elseif ($adapter.NetConnectionStatus -eq 0) {
                $infoBox.AppendText("Status: Getrennt`r`n") 
            }
            else {
                $infoBox.AppendText("Status: $($adapter.NetConnectionStatus)`r`n")
            }
            
            # IP-Konfiguration für diesen Adapter abrufen
            $config = Get-WmiObject -Class Win32_NetworkAdapterConfiguration | Where-Object { $_.Index -eq $adapter.Index }
            if ($config -and $config.IPEnabled) {
                $infoBox.SelectionColor = [System.Drawing.Color]::Blue
                $infoBox.AppendText("`r`nIP-KONFIGURATION:`r`n")
                $infoBox.SelectionColor = [System.Drawing.Color]::Black
                
                $infoBox.AppendText("DHCP aktiviert: $($config.DHCPEnabled)`r`n")
                
                if ($config.IPAddress) {
                    for ($i = 0; $i -lt $config.IPAddress.Length; $i++) {
                        $infoBox.AppendText("IP-Adresse: $($config.IPAddress[$i])`r`n")
                    }
                }
            }
            
            $adapterIndex++
        }
    }
    catch {
        $infoBox.SelectionColor = [System.Drawing.Color]::Red
        $infoBox.AppendText("Fehler beim Abrufen der Netzwerk-Informationen: $_`r`n")
    }
}

function Get-SystemInfo {
    param (
        [System.Windows.Forms.RichTextBox]$infoBox
    )
    
    $infoBox.Clear()
    $infoBox.SelectionColor = [System.Drawing.Color]::DarkBlue
    $infoBox.AppendText("===== SYSTEM-INFORMATIONEN =====`r`n`r`n")
    
    try {
        # Betriebssystem-Informationen
        $infoBox.SelectionColor = [System.Drawing.Color]::Blue
        $infoBox.AppendText("BETRIEBSSYSTEM:`r`n")
        $infoBox.SelectionColor = [System.Drawing.Color]::Black
        
        $osInfo = Get-WmiObject -Class Win32_OperatingSystem
        $infoBox.AppendText("Name: $($osInfo.Caption)`r`n")
        $infoBox.AppendText("Version: $($osInfo.Version)`r`n")
        $infoBox.AppendText("Build: $($osInfo.BuildNumber)`r`n")
        $infoBox.AppendText("Architektur: $($osInfo.OSArchitecture)`r`n")
        
        # Installationsdatum konvertieren
        $installDate = $osInfo.ConvertToDateTime($osInfo.InstallDate)
        $infoBox.AppendText("Installiert am: $($installDate.ToString('dd.MM.yyyy'))`r`n")
        
        # System-Uptime
        $uptime = (Get-Date) - $osInfo.ConvertToDateTime($osInfo.LastBootUpTime)
        $infoBox.AppendText("Letzter Neustart: $($osInfo.ConvertToDateTime($osInfo.LastBootUpTime))`r`n")
        $infoBox.AppendText("Uptime: $($uptime.Days) Tage, $($uptime.Hours) Stunden, $($uptime.Minutes) Minuten`r`n`r`n")
        
        # Computer-Informationen
        $infoBox.SelectionColor = [System.Drawing.Color]::Blue
        $infoBox.AppendText("COMPUTER-INFORMATIONEN:`r`n")
        $infoBox.SelectionColor = [System.Drawing.Color]::Black
        
        $computerSystem = Get-WmiObject -Class Win32_ComputerSystem
        $infoBox.AppendText("Hersteller: $($computerSystem.Manufacturer)`r`n")
        $infoBox.AppendText("Modell: $($computerSystem.Model)`r`n")
        $infoBox.AppendText("Name: $($computerSystem.Name)`r`n")
        $infoBox.AppendText("Domäne/Arbeitsgruppe: $($computerSystem.Domain)`r`n")
    }
    catch {
        $infoBox.SelectionColor = [System.Drawing.Color]::Red
        $infoBox.AppendText("Fehler beim Abrufen der System-Informationen: $_`r`n")
    }
}

# Exportiere die Funktionen
Export-ModuleMember -Function Get-CPUInfo, Get-RAMInfo, Get-GPUInfo, Get-DiskInfo, Get-NetworkInfo, Get-SystemInfo
