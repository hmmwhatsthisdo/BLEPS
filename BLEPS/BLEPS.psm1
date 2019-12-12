# Get all of the pub/priv scripts 
$Scripts = @{
	Public = Get-ChildItem "$PSScriptRoot\Public\*.ps1" -ErrorAction SilentlyContinue
	Private = Get-ChildItem "$PSScriptRoot\Private\*.ps1" -ErrorAction SilentlyContinue
}

# Import them
foreach ($Type in @("Public","Private")) {
	Write-Verbose "Importing $Type functions..."
	foreach ($ImportScript in $Scripts.$Type) {
		Write-Verbose "Importing function $($ImportScript.Basename)..."
		try {
			. $ImportScript.FullName
		} 
		catch {
			Write-Error "Failed to import $type function $($ImportScript.BaseName): $_"
		}
		
	}
}

# Add Windows Runtime interop assembly
Add-Type -AssemblyName System.Runtime.WindowsRuntime

# Attempt to import Windows.Devices.Bluetooth via UWP interop
try {
    [Windows.Devices.Bluetooth.BluetoothAdapter, Windows.Devices.Bluetooth, ContentType = WindowsRuntime] | Out-Null
} catch [System.Management.Automation.RuntimeException] {
    if ($_.FullyQualifiedErrorId -eq "TypeNotFound") {
        throw "Unable to locate UWP Bluetooth assemblies."
    } else {
        throw
    }
}


# Export our functions
$Scripts.Public | ForEach-Object BaseName | Export-ModuleMember



