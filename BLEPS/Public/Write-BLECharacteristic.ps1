function Write-BLECharacteristic {
    [Alias("Set-BLECharacteristicData")]
    [CmdletBinding()]
    param (
        # The characteristic to write to.
        [Parameter(
            Mandatory,
            ValueFromPipeline
        )]
        [Windows.Devices.Bluetooth.GenericAttributeProfile.GattCharacteristic[]]
        $InputObject,

        # The data stream to retrieve data from.
        [Parameter(
            Mandatory,
            Position = 0,
            ParameterSetName = "DataStream"
        )]
        [Alias(
            "Stream"
        )]
        [System.IO.MemoryStream]
        $DataStream,

        # The byte array to retrieve data from.
        [Parameter(
            Mandatory,
            Position = 0,
            ParameterSetName = "DataByteArray"
        )]
        [Alias(
            "Byte",
            "ByteArray"
        )]
        [byte[]]
        $DataByteArray,

        # The WinRT IBuffer to retrieve data from.
        [Parameter(
            Mandatory,
            Position = 0,
            ParameterSetName = "DataBuffer"
        )]
        [Alias(
            "Buffer"
        )]
        [Windows.Storage.Streams.IBuffer]
        $DataBuffer,

        [Switch]
        $NoResponse

    )
    
    begin {

        # Convert data to an IBuffer if needed

        If ($PSCmdlet.ParameterSetName -eq "DataByteArray") {
            Write-Verbose "Converting data byte[] to IBuffer..."
            $DataBuffer = [System.Runtime.InteropServices.WindowsRuntime.WindowsRuntimeBufferExtensions]::AsBuffer($DataByteArray)
        } elseif ($PSCmdlet.ParameterSetName -eq "DataStream") {
            Write-Verbose "Converting data MemoryStream to IBuffer..."
            $DataBuffer = [System.Runtime.InteropServices.WindowsRuntime.WindowsRuntimeBufferExtensions]::GetWindowsRuntimeBuffer($DataStream)
        }

        $WriteOption = $(
            If ($NoResponse) {
                [Windows.Devices.Bluetooth.GenericAttributeProfile.GattWriteOption]::WriteWithoutResponse
            } else {
                [Windows.Devices.Bluetooth.GenericAttributeProfile.GattWriteOption]::WriteWithResponse
            }
        )

    }
    
    process {
        $InputObject `
        | ForEach-Object WriteValueWithResultAsync $DataBuffer $WriteOption `
        | Wait-WinRTAsync -OutputType ([Windows.Devices.Bluetooth.GenericAttributeProfile.GattWriteResult]) `
        | ForEach-Object {
            if ($_.Status -ne "Success") {
                Write-Error "Received error status $($_.Status) from WriteValueWithResultAsync()"
            }
        }
    }
    
    end {
        
    }
}