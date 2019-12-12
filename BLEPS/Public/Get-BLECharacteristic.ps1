function Get-BLECharacteristic {
    [OutputType([Windows.Devices.Bluetooth.GenericAttributeProfile.GattCharacteristics])]
    [CmdletBinding()]
    param (
        # A pre-existing BluetoothLEDevice object
        [Parameter(
            Mandatory,
            ValueFromPipeline,
            ParameterSetName = "InputObject"
        )]
        [Windows.Devices.Bluetooth.GenericAttributeProfile.GattDeviceService[]]
        $InputObject,

        # The UUID of a target characteristic
        [Parameter(
            ParameterSetName = "InputObject"
        )]
        [Guid]
        $CharacteristicUuid
    )
    
    begin {
        
    }
    
    process {
        $InputObject `
        | ForEach-Object {
            If ($null -ne $CharacteristicUuid) {
                $_.GetCharacteristicsForUuidAsync($CharacteristicUuid)
            } Else {
                $_.GetCharacteristicsAsync()
            }
        } `
        | Wait-WinRTAsync -OutputType ([Windows.Devices.Bluetooth.GenericAttributeProfile.GattCharacteristicsResult]) `
        | ForEach-Object {
            [Windows.Devices.Bluetooth.GenericAttributeProfile.GattCharacteristicsResult]$result = $_
            if ($result.Status -ne "Success") {
                Write-Error "Received error status $($result.Status) from GetCharacteristicsAsync()"
            } else {
                $result.Characteristics
            }
        }
    }
    
    end {
        
    }
}