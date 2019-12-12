function Get-BLEService {
    [OutputType([Windows.Devices.Bluetooth.GenericAttributeProfile.GattDeviceService])]
    [CmdletBinding()]
    param (
        # A pre-existing BluetoothLEDevice object
        [Parameter(
            Mandatory,
            ValueFromPipeline,
            ParameterSetName = "InputObject"
        )]
        [Windows.Devices.Bluetooth.BluetoothLEDevice[]]
        $InputObject,

        # The UUID of a target service
        [Parameter(
            ParameterSetName = "InputObject"
        )]
        [Guid]
        $ServiceUuid
    )
    
    begin {
        
    }
    
    process {
        $InputObject `
        | ForEach-Object {
            If ($null -ne $ServiceUuid) {
                $_.GetGattServicesForUuidAsync($ServiceUuid)
            } Else {
                $_.GetGattServicesAsync()
            }
        } `
        | Wait-WinRTAsync -OutputType ([Windows.Devices.Bluetooth.GenericAttributeProfile.GattDeviceServicesResult]) `
        | ForEach-Object {
            [Windows.Devices.Bluetooth.GenericAttributeProfile.GattDeviceServicesResult]$result = $_
            if ($result.Status -ne "Success") {
                Write-Error "Received error status $($result.Status) from GetGattServicesAsync()"
            } else {
                $result.Services
            }
        }
    }
    
    end {
        
    }
}