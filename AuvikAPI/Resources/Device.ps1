function Get-AuvikDevicesInfo {
    [CmdletBinding(DefaultParameterSetName = 'index')]
    Param (
        [Parameter(ParameterSetName = 'show')]
        [String[]]$Id,
 
        [Parameter(ParameterSetName = 'index')]
        [String[]]$Networks = '',

        [Parameter(ParameterSetName = 'index')]
        [ValidateSet('unknown', 'switch', 'l3Switch', 'router', `
            'accessPoint', 'firewall', 'workstation', 'server', 'storage', `
            'printer', 'copier', 'hypervisor', 'multimedia', 'phone', `
            'tablet', 'handheld', 'virtualAppliance', 'bridge', `
            'controller', 'hub', 'modem', 'ups', 'module', 'loadBalancer', `
            'camera', 'telecommunications', 'packetProcessor', 'chassis', `
            'airConditioner', 'virtualMachine', 'pdu', 'ipPhone', `
            'backhaul', 'internetOfThings', 'voipSwitch', 'stack', `
            'backupDevice', 'timeClock', 'lightingDevice', 'audioVisual', `
            'securityAppliance', 'utm', 'alarm', 'buildingManagement', `
            'ipmi', 'thinAccessPoint', 'thinClient')]
        [String]$DeviceType = '',

        [Parameter(ParameterSetName = 'index')]
        [String]$MakeModel = '',

        [Parameter(ParameterSetName = 'index')]
        [String]$VendorName = '',

        [Parameter(ParameterSetName = 'index')]
        [ValidateSet('online', 'offline', 'unreachable', 'testing', `
            'unknown', 'dormant', 'notPresent', 'lowerLayerDown')]
        [String]$Status = '',

        [Parameter(ParameterSetName = 'index')]
        [datetime]$ModifiedAfter,

        [Parameter(ParameterSetName = 'index')]
        [String[]]$Tenants = '',

        [Parameter(ParameterSetName = 'show')]
        [Parameter(ParameterSetName = 'index')]
        [ValidateSet('discoveryStatus', 'components', 'connectedDevices', `
            'configurations', 'manageStatus', 'interfaces')]
        [String[]]$IncludeDetailFields = ''

    )

Begin {
    $data = @()
    $qparams = @{}
    $x_api_authorization = "$($Auvik_API_Credential.UserName):$([Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($Auvik_API_Credential.Password)))"
    $x_api_authorization = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($x_api_authorization))
}

Process {
    if ($IncludeDetailFields) {
        $qparams += @{'include' = 'deviceDetail'; 'fields[deviceDetail]' = $Fields -join ','}
    }

    if ($PSCmdlet.ParameterSetName -eq 'index') {
        $Id = @('')
        if ($Tenants) {
            $qparams += @{'tenants' = $Tenants -join ','}
        }
        if ($DeviceType) {
            $qparams += @{'filter[deviceType]' = $DeviceType}
        }
        if ($Networks) {
            $qparams += @{'filter[networks]' = $Networks -join ','}
        }
        if ($MakeModel) {
            $qparams += @{'filter[makeModel]' = "`"$MakeModel`""}
        }
        if ($VendorName) {
            $qparams += @{'filter[vendorName]' = "`"$VendorName`""}
        }
        if ($Status) {
            $qparams += @{'filter[onlineStatus]' = $Status}
        }
        if ($ModifiedAfter) {
            $qparams += @{'filter[modifiedAfter]' = $ModifiedAfter}
        }
    }
    else {
        #Parameter set "Show" is selected
    }

    foreach ($deviceId IN $Id) {
        $resource_uri = ('/v1/inventory/device/info/{0}' -f $deviceId)

        if ($qparams.Count -gt 0) { $resource_uri += '?' + $(($qparams.GetEnumerator() | ForEach-Object {"$($_.Name)=$($_.Value)"}) -join '&') }

        $attempt=0
        do {
            $attempt+=1
            if ($attempt -gt 1) {Start-Sleep 2}
            Write-Debug "Testing $($Auvik_Base_URI + $resource_uri)"
            $rest_output = try {
                $Null = $AuvikAPI_Headers.Add("Authorization", "Basic $x_api_authorization")
                Invoke-RestMethod -method 'GET' -uri ($Auvik_Base_URI + $resource_uri) -Headers $AuvikAPI_Headers `
                            -ErrorAction SilentlyContinue
            } catch [System.Net.WebException] { 
                $_.Exception.Response 
            } catch {
                Write-Error $_
            } finally {
                $Null = $AuvikAPI_Headers.Remove('Authorization')
            }
            Write-Verbose "Status Code Returned: $([int]$rest_output.StatusCode)"
        } until ($([int]$rest_output.StatusCode) -ne 502 -or $attempt -ge 5)
        $data += $rest_output
    }
}

End {
    return $data
}

}


function Get-AuvikDevicesDetails {
    [CmdletBinding(DefaultParameterSetName = 'index')]
    Param (
        [Parameter(ParameterSetName = 'show')]
        [String[]]$Id,
 
        [Parameter(ParameterSetName = 'index')]
        [ValidateSet('disabled', 'determining', 'notSupported', `
            'notAuthorized', 'authorizing', 'authorized', 'privileged')]
        [String]$SNMPDiscovery = '',

        [Parameter(ParameterSetName = 'index')]
        [ValidateSet('disabled', 'determining', 'notSupported', `
            'notAuthorized', 'authorizing', 'authorized', 'privileged')]
        [String]$WMIDiscovery = '',

        [Parameter(ParameterSetName = 'index')]
        [ValidateSet('disabled', 'determining', 'notSupported', `
            'notAuthorized', 'authorizing', 'authorized', 'privileged')]
        [String]$LoginDiscovery = '',

        [Parameter(ParameterSetName = 'index')]
        [ValidateSet('disabled', 'determining', 'notSupported', `
            'notAuthorized', 'authorizing', 'authorized', 'privileged')]
        [String]$VMWareDiscovery = '',

        [Parameter(ParameterSetName = 'index')]
        [String[]]$Tenants = '',

        [Parameter(ParameterSetName = 'index')]
        [Nullable[Boolean]]$ManagedStatus
    )

Begin {
    $data = @()
    $qparams = @{}
    $x_api_authorization = "$($Auvik_API_Credential.UserName):$([Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($Auvik_API_Credential.Password)))"
    $x_api_authorization = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($x_api_authorization))
}

Process {    

    if ($PSCmdlet.ParameterSetName -eq 'index') {
        $Id = @('')
        if ($Tenants) {
            $qparams += @{'tenants' = $Tenants -join ','}
        }
        if ($SNMPDiscovery) {
            $qparams += @{'filter[discoverySNMP]' = $SNMPDiscovery}
        }
        if ($WMIDiscovery) {
            $qparams += @{'filter[discoveryWMI]' = $WMIDiscovery}
        }
        if ($LoginDiscovery) {
            $qparams += @{'filter[discoveryLogin]' = $LoginDiscovery}
        }
        if ($VMWareDiscovery) {
            $qparams += @{'filter[discoveryVMWare]' = $VMWareDiscovery}
        }
        if ($Null -ne $ManagedStatus) {
            if ($ManagedStatus -eq $True) {
                $qparams += @{'filter[managedStatus]' = 'true'}
            } else {
                $qparams += @{'filter[managedStatus]' = 'false'}
            }
        }
    }
    else {
        #Parameter set "Show" is selected
    }

    foreach ($deviceId IN $Id) {
        $resource_uri = ('/v1/inventory/device/detail/{0}' -f $deviceId)

        if ($qparams.Count -gt 0) { $resource_uri += '?' + $(($qparams.GetEnumerator() | ForEach-Object {"$($_.Name)=$($_.Value)"}) -join '&') }

        $attempt=0
        do {
            $attempt+=1
            if ($attempt -gt 1) {Start-Sleep 2}
            Write-Debug "Testing $($Auvik_Base_URI + $resource_uri)"
            $rest_output = try {
                $Null = $AuvikAPI_Headers.Add("Authorization", "Basic $x_api_authorization")
                Invoke-RestMethod -method 'GET' -uri ($Auvik_Base_URI + $resource_uri) -Headers $AuvikAPI_Headers `
                    -ErrorAction SilentlyContinue
            } catch [System.Net.WebException] { 
                $_.Exception.Response 
            } catch {
                Write-Error $_
            } finally {
                $Null = $AuvikAPI_Headers.Remove('Authorization')
            }
            Write-Verbose "Status Code Returned: $([int]$rest_output.StatusCode)"
        } until ($([int]$rest_output.StatusCode) -ne 502 -or $attempt -ge 5)
        $data += $rest_output
    }
}

End {
    return $data
}

}

function Get-AuvikDevicesExtendedDetails {
    [CmdletBinding(DefaultParameterSetName = 'index')]
    Param (
        [Parameter(ParameterSetName = 'show')]
        [String]$Id,
 
        [Parameter(ParameterSetName = 'index', Mandatory=$True)]
        [ValidateSet('unknown', 'switch', 'l3Switch', 'router', `
            'accessPoint', 'firewall', 'workstation', 'server', 'storage', `
            'printer', 'copier', 'hypervisor', 'multimedia', 'phone', `
            'tablet', 'handheld', 'virtualAppliance', 'bridge', `
            'controller', 'hub', 'modem', 'ups', 'module', 'loadBalancer', `
            'camera', 'telecommunications', 'packetProcessor', 'chassis', `
            'airConditioner', 'virtualMachine', 'pdu', 'ipPhone', `
            'backhaul', 'internetOfThings', 'voipSwitch', 'stack', `
            'backupDevice', 'timeClock', 'lightingDevice', 'audioVisual', `
            'securityAppliance', 'utm', 'alarm', 'buildingManagement', `
            'ipmi', 'thinAccessPoint', 'thinClient')]
        [String]$DeviceType = '',

        [Parameter(ParameterSetName = 'index')]
        [datetime]$ModifiedAfter,

        [Parameter(ParameterSetName = 'index')]
        [String[]]$Tenants = ''

    )

Begin {
    $data = @()
    $qparams = @{}
    $x_api_authorization = "$($Auvik_API_Credential.UserName):$([Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($Auvik_API_Credential.Password)))"
    $x_api_authorization = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($x_api_authorization))
}

Process {    

    if ($PSCmdlet.ParameterSetName -eq 'index') {
        $Id = @('')
        if ($Tenants) {
            $qparams += @{'tenants' = $Tenants -join ','}
        }
        if ($DeviceType) {
            $qparams += @{'filter[deviceType]' = $DeviceType}
        }
        if ($ModifiedAfter) {
            $qparams += @{'filter[modifiedAfter]' = $ModifiedAfter}
        }
    }
    else {
        #Parameter set "Show" is selected
    }

    foreach ($deviceId IN $Id) {
        $resource_uri = ('/v1/inventory/device/detail/extended/{0}' -f $deviceId)

        if ($qparams.Count -gt 0) { $resource_uri += '?' + $(($qparams.GetEnumerator() | ForEach-Object {"$($_.Name)=$($_.Value)"}) -join '&') }

        $attempt=0
        do {
            $attempt+=1
            if ($attempt -gt 1) {Start-Sleep 2}
            Write-Debug "Testing $($Auvik_Base_URI + $resource_uri)"
            $rest_output = try {
                $Null = $AuvikAPI_Headers.Add("Authorization", "Basic $x_api_authorization")
                Invoke-RestMethod -method 'GET' -uri ($Auvik_Base_URI + $resource_uri) -Headers $AuvikAPI_Headers `
                    -ErrorAction SilentlyContinue
            } catch [System.Net.WebException] { 
                $_.Exception.Response 
            } catch {
                Write-Error $_
            } finally {
                $Null = $AuvikAPI_Headers.Remove('Authorization')
            }
            Write-Verbose "Status Code Returned: $([int]$rest_output.StatusCode)"
        } until ($([int]$rest_output.StatusCode) -ne 502 -or $attempt -ge 5)
        $data += $rest_output
    }
}

End {
    return $data
}

}
