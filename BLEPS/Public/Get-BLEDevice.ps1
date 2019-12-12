function Get-BLEDevice {
    [OutputType([Windows.Devices.Bluetooth.BluetoothLEDevice])]
    [CmdletBinding(
        DefaultParameterSetName = "All"
    )]
    param (
        # The device's appearance.
        [Parameter(
            Mandatory,
            Position = 0,
            ParameterSetName = "ByAppearance"
        )]
        [Windows.Devices.Bluetooth.BluetoothLEAppearance]
        $Appearance,

        # The device's address, expressed as an unsigned long integer (uint64).
        [Parameter(
            Mandatory,
            Position = 0,
            ParameterSetName = "ByAddress"
        )]
        [uint64]
        $BluetoothAddress,

        # The device's connection status.
        [Parameter(
            Mandatory,
            Position = 0,
            ParameterSetName = "ByConnectionStatus"
        )]
        [Windows.Devices.Bluetooth.BluetoothConnectionStatus]
        $ConnectionStatus,

        # The device's friendly name.
        [Parameter(
            Mandatory,
            Position = 0,
            ParameterSetName = "ByDeviceName"
        )]
        [String]
        $DeviceName,

        # The device's pairing state. A true value indicates the device is paired.
        [Parameter(
            Mandatory,
            ParameterSetName = "ByPairingState"
        )]
        [Switch]
        $PairingState
    )
    
    begin {
        
    }
    
    process {
        # Find the right AQS selector to use for our parameter set
        $Selector = $(
            switch ($PSCmdlet.ParameterSetName) {
                "All" {
                    [Windows.Devices.Bluetooth.BluetoothLEDevice]::GetDeviceSelector()
                }
                "ByAppearance" {
                    [Windows.Devices.Bluetooth.BluetoothLEDevice]::GetDeviceSelectorFromAppearance($Appearance)
                }
                "ByAddress" {
                    [Windows.Devices.Bluetooth.BluetoothLEDevice]::GetDeviceSelectorFromBluetoothAddress($BluetoothAddress)
                }
                "ByConnectionStatus" {
                    [Windows.Devices.Bluetooth.BluetoothLEDevice]::GetDeviceSelectorFromConnectionStatus($ConnectionStatus)
                }
                "ByDeviceName" {
                    [Windows.Devices.Bluetooth.BluetoothLEDevice]::GetDeviceSelectorFromDeviceName($DeviceName)
                }
                "ByPairingState" {
                    [Windows.Devices.Bluetooth.BluetoothLEDevice]::GetDeviceSelectorFromPairingState($PairingState)
                }
            }
        )

        # Enumerate devices matching our selector 
        # (This will automatically perform device discovery)
        $SearchResults = [Windows.Devices.Enumeration.DeviceInformation]::FindAllAsync($Selector) `
        | Wait-WinRTAsync -OutputType ([Windows.Devices.Enumeration.DeviceInformationCollection])

        $SearchResults | ForEach-Object {
            [Windows.Devices.Bluetooth.BluetoothLEDevice]::FromIdAsync($_.ID)
        } `
        | Wait-WinRTAsync -OutputType ([Windows.Devices.Bluetooth.BluetoothLEDevice])
    }
    
    end {
        
    }
}