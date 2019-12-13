function Read-BLECharacteristic {
    [CmdletBinding()]
    param (
        # The characteristic to read from.
        [Parameter(
            Mandatory,
            ValueFromPipeline
        )]
        [Windows.Devices.Bluetooth.GenericAttributeProfile.GattCharacteristic[]]
        $InputObject,

        # Return data as a stream (System.IO.Stream) instead of a byte array.
        [Parameter(
        )]
        [Switch]
        $AsStream
    )
    
    begin {
        If ($asStream) {
            $BufferConversionMethod = "AsStream"
        } Else {
            $BufferConversionMethod = "ToArray"
        } 

        $BufferConverter = [System.Runtime.InteropServices.WindowsRuntime.WindowsRuntimeBufferExtensions].GetMethod(
            $BufferConversionMethod, 
            [type[]]@(
                [Windows.Storage.Streams.IBuffer]
            )
        )
    }
    
    process {
        $InputObject `
        | ForEach-Object ReadValueAsync `
        | Wait-WinRTAsync -OutputType ([Windows.Devices.Bluetooth.GenericAttributeProfile.GattReadResult]) `
        | ForEach-Object {
            if ($_.Status -ne "Success") {
                Write-Error "Received error status $($_.Status) from ReadValueAsync()"
            } else {
                $BufferConverter.Invoke($null, @($_.Value))
            }
        }
    }
    
    end {
        
    }
}