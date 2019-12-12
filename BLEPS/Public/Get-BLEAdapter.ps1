function Get-BLEAdapter {
    [OutputType([Windows.Devices.Bluetooth.BluetoothAdapter])]
    [CmdletBinding(
        DefaultParameterSetName = "Default"
    )]
    param (
        
        # DeviceID string for the adapter to use.
        [Parameter(
            ParameterSetName = "ByDeviceID",
            Mandatory,
            Position = 0
        )]
        [String]
        $DeviceID,

        # Retrieve all Bluetooth adapters present on the system.
        [Parameter(
            Mandatory,
            ParameterSetName = "All"
        )]
        [Switch]
        $All

    )
    
    begin {
        
    }
    
    process {
        switch ($PSCmdlet.ParameterSetName) {
            "ByDeviceId" { 
                [Windows.Devices.Bluetooth.BluetoothAdapter]::FromIdAsync($DeviceID) `
                | Wait-WinRtAsync -OutputType ([Windows.Devices.Bluetooth.BluetoothAdapter])
            }
            "All" {
                $DeviceFilter = [Windows.Devices.Bluetooth.BluetoothAdapter]::GetDeviceSelector()
                
                [Windows.Devices.Enumeration.DeviceInformationCollection]$Results = [Windows.Devices.Enumeration.DeviceInformation]::FindAllAsync($DeviceFilter) `
                | Wait-WinRTAsync -OutputType ([Windows.Devices.Enumeration.DeviceInformationCollection])

                $Results | Write-Output
            }
            "Default" {
                [Windows.Devices.Bluetooth.BluetoothAdapter]::GetDefaultAsync() `
                | Wait-WinRTAsync -OutputType ([Windows.Devices.Bluetooth.BluetoothAdapter])
            }
        }
    }
    
    end {
        
    }
}