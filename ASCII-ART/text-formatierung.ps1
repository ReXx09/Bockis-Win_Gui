function Write-WrappedOutput {
    param(
        [string]$text,
        [int]$maxWidth = 80,
        [string]$foregroundColor = "White",
        [string]$prefix = "[>] ",
        [string]$continuationPrefix = $null
    )
    
    # Falls kein spezielles Fortsetzungspräfix angegeben wurde, erstelle eines mit Leerzeichen
    if ($null -eq $continuationPrefix) {
        $continuationPrefix = " " * $prefix.Length
    }
    
    # Text in Wörter aufteilen
    $words = $text -split '\s+'
    
    # Erste Zeile mit Hauptpräfix beginnen
    $currentLine = $prefix
    $isFirstLine = $true
    
    foreach ($word in $words) {
        # Prüfen, ob das Wort in die aktuelle Zeile passt
        if (($currentLine.Length + $word.Length + 1) -le $maxWidth) {
            # Leerzeichen hinzufügen, wenn es nicht der Zeilenanfang ist
            $prefixLength = if ($isFirstLine) { $prefix.Length } else { $continuationPrefix.Length }
            if ($currentLine.Length -gt $prefixLength) {
                $currentLine += " "
            }
            $currentLine += $word
        }
        else {
            # Aktuelle Zeile ausgeben
            Write-Host $currentLine -ForegroundColor $foregroundColor
            
            # Neue Zeile mit Fortsetzungspräfix beginnen
            $currentLine = $continuationPrefix + $word
            $isFirstLine = $false
        }
    }
    
    # Letzte Zeile ausgeben
    if ($currentLine.Length -gt 0) {
        Write-Host $currentLine -ForegroundColor $foregroundColor
    }
}

# Beispiele mit verschiedenen Präfixen
$infoPrefix = "[INFO] "
$warnPrefix = "[WARNUNG] "
$errorPrefix = "[FEHLER] "
$setupPrefix = "[SETUP] "

# Info-Nachricht
$updateMessage = "Windows Update wird in den Einstellungen geöffnet"
Write-WrappedOutput -text $updateMessage -foregroundColor "Cyan" -prefix $infoPrefix -maxWidth 80

# Warn-Nachricht mit langem Text
$installMessage = "Bitte folgen Sie den Anweisungen in der Windows-Update-Seite, um Updates zu suchen und zu installieren. Dieser Vorgang kann einige Zeit in Anspruch nehmen und erfordert möglicherweise einen Neustart des Systems."
Write-WrappedOutput -text $installMessage -foregroundColor "Yellow" -prefix $warnPrefix -maxWidth 80

# Fehler-Nachricht mit speziellem Fortsetzungspräfix
$errorMessage = "Bei der Suche nach Updates ist ein Fehler aufgetreten. Bitte stellen Sie sicher, dass Ihre Internetverbindung aktiv ist und versuchen Sie es später erneut."
Write-WrappedOutput -text $errorMessage -foregroundColor "Red" -prefix $errorPrefix -continuationPrefix "        " -maxWidth 80

# Setup-Nachricht
$setupMessage = "Die Installation der gefundenen Updates wird vorbereitet..."
Write-WrappedOutput -text $setupMessage -foregroundColor "Green" -prefix $setupPrefix -maxWidth 80