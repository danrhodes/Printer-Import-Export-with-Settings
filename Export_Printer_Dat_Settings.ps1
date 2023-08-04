# Specify the root directory where the printer folders will be created
$rootDir = "C:\Alamo"

# Create the root directory if it doesn't exist
if (!(Test-Path -Path $rootDir)) {
    New-Item -Path $rootDir -ItemType Directory | Out-Null
}

# Get all printers
$printers = Get-Printer

# Loop over each printer
foreach ($printer in $printers) {
    # Create a new directory for the printer if it doesn't exist
    $printerDir = Join-Path -Path $rootDir -ChildPath $printer.Name
    if (!(Test-Path -Path $printerDir)) {
        New-Item -Path $printerDir -ItemType Directory | Out-Null
    }
    
    # Create the Dat directory inside the printer directory
    $settingsDir = Join-Path -Path $printerDir -ChildPath "Dat"
    if (!(Test-Path -Path $settingsDir)) {
        New-Item -Path $settingsDir -ItemType Directory | Out-Null
    }

    # Create the Driver directory inside the printer directory
    $driverDir = Join-Path -Path $printerDir -ChildPath "Driver"
    if (!(Test-Path -Path $driverDir)) {
        New-Item -Path $driverDir -ItemType Directory | Out-Null
    }

    # Construct the full path to the output file
    $outputFile = Join-Path -Path $settingsDir -ChildPath "$($printer.Name).dat"

    # Export the printer settings
    rundll32 printui.dll,PrintUIEntry /Ss /n "$($printer.Name)" /a "$outputFile" d g
}
