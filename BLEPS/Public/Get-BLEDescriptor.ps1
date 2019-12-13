function Get-BLEDescriptor {
    [CmdletBinding()]
    param (
        # The characteristic to retrieve descriptors for.
        [Parameter(
            Mandatory,
            ValueFromPipeline
        )]
        [Windows.Devices.Bluetooth.GenericAttributeProfile.GattCharacteristic[]]
        $InputObject,

        # The UUID of a target descriptor
        [Parameter(

        )]
        [Guid]
        $DescriptorGuid
    )
    
    begin {
        
    }
    
    process {
        $InputObject `
        | ForEach-Object {
            If ($null -ne $DescriptorGuid) {
                $_.GetDescriptorsForUuidAsync($DescriptorGuid)
            } else {
               $_.GetDescriptorsAsync()
            }
        } `
        | Wait-WinRTAsync -OutputType ([Windows.Devices.Bluetooth.GenericAttributeProfile.GattDescriptorsResult]) `
        | ForEach-Object {
            if ($_.Status -ne "Success") {
                Write-Error "Received error status $($_.Status) from ReadValueAsync()"
            } else {
                $_.Descriptors
            }
        }
    }
    
    end {
        
    }
}