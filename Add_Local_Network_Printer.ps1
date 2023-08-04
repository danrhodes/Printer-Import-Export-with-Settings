Param (
    [Parameter(Mandatory = $true)]
    [string]$DatFile,

    [Parameter(Mandatory = $true)]
    [string]$PrinterName,

    [Parameter(Mandatory = $true)]
    [string]$PrinterIP,

    [Parameter(Mandatory = $false)]
    [bool]$ForceInstall = $false,

    [Parameter(Mandatory = $true)]
    [string]$DriverName
)

# Specify the log file path
$logFilePath = "C:\Alamo\Printers.log"

# Create the logging directory if it doesn't exist
if (!(Test-Path -Path "C:\Alamo")) {
    New-Item -Path "C:\Alamo" -ItemType Directory | Out-Null
}

# Function to log messages
function Write-Log {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$timestamp - $Message"
    
    Add-Content -Path $logFilePath -Value $logMessage
    Write-Output $logMessage
}

try {
    # Check if the printer with the new name already exists
    if ((Get-Printer | Where-Object { $_.Name -eq $PrinterName }) -and !$ForceInstall) {
        Write-Log "Printer $PrinterName already exists. Use -ForceInstall to install anyway."
        return
    }

    # Create the printer port if it doesn't exist
    if (!(Get-PrinterPort | Where-Object { $_.Name -eq "IP_$PrinterIP" })) {
        Add-PrinterPort -Name "IP_$PrinterIP" -PrinterHostAddress "$PrinterIP"
    }

    # Construct the full path to the INF and DAT files
    $InfPath = Join-Path -Path $PSScriptRoot -ChildPath "Driver\"
    $DatPath = Join-Path -Path $PSScriptRoot -ChildPath "Dat\$DatFile"
    $InfPath
    $DatPath

    # Use full path for the pnputil command
    $PnPUtilPath = "${Env:SystemRoot}\Sysnative\pnputil.exe"
    $PNPUtilCommand = "$PnPUtilPath /add-driver `"$InfPath\*.inf`" /install /subdirs"
    Invoke-Expression $PNPUtilCommand
    Write-Log "Printer driver installed successfully."

    # Add driver to the list of available printers
    Add-PrinterDriver -Name $DriverName -Verbose

    # Add the printer
    Write-Log "Adding the printer $PrinterName..."
    Add-Printer -Name $PrinterName -DriverName $DriverName -PortName "IP_$PrinterIP"
    Write-Log "Printer $PrinterName added successfully."

    # Add printer settings
    Write-Log "Adding printer settings for $PrinterName..."
    $settingsCmd = "$env:windir\System32\rundll32.exe $env:windir\System32\printui.dll,PrintUIEntry /Sr /n ""$PrinterName"" /a ""$DatPath"" d g r"
    Invoke-Expression $settingsCmd    
    Write-Log "Settings added to printer $PrinterName successfully."

    # There's no need to rename the printer because it's already being installed with the new name.
}
catch {
    Write-Log "An error occurred: $_"
    exit 1
}
