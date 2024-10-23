# Script d'installation pilotes et imprimantes
# ip-printer-install.ps1
# Author: Jr0w3
# Release: 23/10/2024


# VARS
$driverName = "XXXX" # Nom du driver dans le package
$infPath = "XXXX" # Chemin vers le fichier .inf du package
$printerName = "XXXX" # Nom à donner à l'imprimante
$printerIP = "XXXX" # Adresse IP de l'imprimante

function Write-CustomLog {
    param (
        [ValidateSet("Information", "Warning", "Error")]
        [string]$LogEntryType,
        [string]$LogMessage
    )

    $logName = "Application"
    $source = "PowerShellScripts"
    $fixedEventID = 1000  # EventID fixe

    # Vérifier si la source existe, sinon la créer
    if (-not [System.Diagnostics.EventLog]::SourceExists($source)) {
        New-EventLog -LogName $logName -Source $source
    }

    # Écrire l'événement dans l'Event Viewer
    Write-EventLog -LogName $logName -Source $source -EventID $fixedEventID -EntryType $LogEntryType -Message $LogMessage
    Write-Host $LogMessage
}

# Test d'accès au fichier
    $IsPathExist = Test-Path -Path $infPath -ErrorAction Stop
    if ($IsPathExist -eq $false) {
    Write-CustomLog -LogEntryType "Error" -LogMessage "Impossible d'accéder au fichier: $infPath"
    Exit 1  # Indique une erreur
    }



# Vérifier si le pilote n'est pas déjà présent:
$driver = Get-PrinterDriver | Where-Object { $_.Name -eq $driverName }

if ($null -eq $driver) {
    # Si $driver n'est pas défini, on install le pilote avec pnputil
    try {
        Write-Host "Installation du pilote à partir de $infPath..."
        pnputil.exe -i -a $infPath
        Add-PrinterDriver -Name $driverName
        Write-CustomLog -LogEntryType "Information" -LogMessage "Pilote $driverName ajouté avec succès."
    } catch {
        Write-CustomLog -LogEntryType "Error" -LogMessage "Erreur lors de l'installation du pilote : $_"
        exit
    }
} else {
     Write-Host "Le pilote $driverName est déjà installé."
}

# Vérifier si l'imprimante est déjà installée
$printer = Get-Printer | Where-Object { $_.Name -eq $printerName }

if ($printer -eq $null) {
    # L'imprimante n'est pas installée, donc on l'ajoute
    try {
            $portName = "IP_$printerIP"
            $port = Get-PrinterPort | Where-Object { $_.Name -eq $portName }

            if ($port -eq $null) {
            # Si le port n'existe pas, on le créer
                try {
                    Write-Host "Ajout du port d'imprimante pour l'adresse IP $printerIP..."
                    Add-PrinterPort -Name $portName -PrinterHostAddress $printerIP
                    Write-CustomLog -LogEntryType "Information" -LogMessage "Port $portName ajouté avec succès."
                } catch {
                    Write-CustomLog -LogEntryType "Error" -LogMessage "Erreur lors de l'ajout du port $portName"
                }
            } else {
            Write-Host "Le Port $portName existe déjà."
        }

        Write-Host "Ajout de l'imprimante $printerName..."
        Add-Printer -Name $printerName -DriverName $driverName -PortName $portName

        Write-CustomLog -LogEntryType "Information" -LogMessage "Imprimante $printerName ajoutée avec succès."
    } catch {
        Write-CustomLog -LogEntryType "Error" -LogMessage "Erreur lors de l'ajout de l'imprimante : $printerName"
    }
} else {
    Write-Host "L'imprimante $printerName est déjà installée."
}
