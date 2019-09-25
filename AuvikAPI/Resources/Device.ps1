function Get-AuvikDevicesInfo {
    [CmdletBinding(DefaultParameterSetName = 'index-after')]
    Param (
        [Parameter(ParameterSetName = 'show-after')]
        [Parameter(ParameterSetName = 'show-before')]
        [String[]]$Id,

        [Parameter(ParameterSetName = 'index-after')]
        [Parameter(ParameterSetName = 'index-before')]
        [String[]]$Networks = '',

        [Parameter(ParameterSetName = 'index-after')]
        [Parameter(ParameterSetName = 'index-before')]
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

        [Parameter(ParameterSetName = 'index-after')]
        [Parameter(ParameterSetName = 'index-before')]
        [String]$MakeModel = '',

        [Parameter(ParameterSetName = 'index-after')]
        [Parameter(ParameterSetName = 'index-before')]
        [String]$VendorName = '',

        [Parameter(ParameterSetName = 'index-after')]
        [Parameter(ParameterSetName = 'index-before')]
        [ValidateSet('online', 'offline', 'unreachable', 'testing', `
            'unknown', 'dormant', 'notPresent', 'lowerLayerDown')]
        [String]$Status = '',

        [Parameter(ParameterSetName = 'index-after')]
        [Parameter(ParameterSetName = 'index-before')]
        [datetime]$ModifiedAfter,

        [Parameter(ParameterSetName = 'index-after')]
        [Parameter(ParameterSetName = 'index-before')]
        [String[]]$Tenants = '',

        [ValidateSet('discoveryStatus', 'components', 'connectedDevices', `
            'configurations', 'manageStatus', 'interfaces')]
        [String[]]$IncludeDetailFields = '',

        [Parameter(ParameterSetName = 'index-after')]
        [Parameter(ParameterSetName = 'show-after')]
        [String]$After,

        [Parameter(ParameterSetName = 'index-before')]
        [Parameter(ParameterSetName = 'show-before')]
        [String]$Before,

        [ValidateRange(1, 1000)]
        [Int] $Limit
    )

Begin {
    $data = @()
    $qparams = @{}
    $x_api_authorization = "$($Auvik_API_Credential.UserName):$([Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($Auvik_API_Credential.Password)))"
    $x_api_authorization = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($x_api_authorization))
}

Process {
    If ($IncludeDetailFields) {
        $qparams += @{'include' = 'deviceDetail'; 'fields[deviceDetail]' = $IncludeDetailFields -join ','}
    }

    If ($PSCmdlet.ParameterSetName -eq 'index') {
        $Id = @('')
        If ($Tenants) {
            $qparams += @{'tenants' = $Tenants -join ','}
        }
        If ($DeviceType) {
            $qparams += @{'filter[deviceType]' = $DeviceType}
        }
        If ($Networks) {
            $qparams += @{'filter[networks]' = $Networks -join ','}
        }
        If ($MakeModel) {
            $qparams += @{'filter[makeModel]' = "`"$MakeModel`""}
        }
        If ($VendorName) {
            $qparams += @{'filter[vendorName]' = "`"$VendorName`""}
        }
        If ($Status) {
            $qparams += @{'filter[onlineStatus]' = $Status}
        }
        If ($ModifiedAfter) {
            $qparams += @{'filter[modifiedAfter]' = $ModifiedAfter.ToString('yyyy-MM-ddTHH:mm:ss.fffzzz')}
        }
    }
    Else {
        #Parameter set "Show" is selected
    }

    ForEach ($deviceId IN $Id) {
        $resource_uri = ('/v1/inventory/device/info')
        If (!($Null -eq $deviceId) -and $deviceId -gt '') {
            $resource_uri = ('/v1/inventory/device/info/{0}' -f $deviceId)
        }

        $attempt=0
        Do {
            $attempt+=1
            If ($attempt -gt 1) {Start-Sleep 2}
            Write-Debug "Testing $($Auvik_Base_URI + $resource_uri)$(If ($qparams.Count -gt 0) {'?' + $(($qparams.GetEnumerator() | ForEach-Object {"$($_.Name)=$($_.Value)"}) -join '&') })"
            $rest_output = try {
                $Null = $AuvikAPI_Headers.Add("Authorization", "Basic $x_api_authorization")
                Invoke-RestMethod -method 'GET' -uri ($Auvik_Base_URI + $resource_uri) -Headers $AuvikAPI_Headers -Body $qparams -ErrorAction SilentlyContinue
            } catch [System.Net.WebException] {
                $_.Exception.Response
            } catch {
                Write-Error $_
            } finally {
                $Null = $AuvikAPI_Headers.Remove('Authorization')
            }
            Write-Verbose "Status Code Returned: $([int]$rest_output.StatusCode)"
        } Until ($([int]$rest_output.StatusCode) -ne 502 -or $attempt -ge 5)
        $data += $rest_output
    }
}

End {
    Return $data
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

    If ($PSCmdlet.ParameterSetName -eq 'index') {
        $Id = @('')
        If ($Tenants) {
            $qparams += @{'tenants' = $Tenants -join ','}
        }
        If ($SNMPDiscovery) {
            $qparams += @{'filter[discoverySNMP]' = $SNMPDiscovery}
        }
        If ($WMIDiscovery) {
            $qparams += @{'filter[discoveryWMI]' = $WMIDiscovery}
        }
        If ($LoginDiscovery) {
            $qparams += @{'filter[discoveryLogin]' = $LoginDiscovery}
        }
        If ($VMWareDiscovery) {
            $qparams += @{'filter[discoveryVMWare]' = $VMWareDiscovery}
        }
        If ($Null -ne $ManagedStatus) {
            If ($ManagedStatus -eq $True) {
                $qparams += @{'filter[managedStatus]' = 'true'}
            } Else {
                $qparams += @{'filter[managedStatus]' = 'false'}
            }
        }
    }
    Else {
        #Parameter set "Show" is selected
    }

    ForEach ($deviceId IN $Id) {
        $resource_uri = ('/v1/inventory/device/detail')
        If (!($Null -eq $deviceId) -and $deviceId -gt '') {
            $resource_uri = ('/v1/inventory/device/detail/{0}' -f $deviceId)
        }

        $attempt=0
        Do {
            $attempt+=1
            If ($attempt -gt 1) {Start-Sleep 2}
            Write-Debug "Testing $($Auvik_Base_URI + $resource_uri)$(If ($qparams.Count -gt 0) {'?' + $(($qparams.GetEnumerator() | ForEach-Object {"$($_.Name)=$($_.Value)"}) -join '&') })"
            $rest_output = try {
                $Null = $AuvikAPI_Headers.Add("Authorization", "Basic $x_api_authorization")
                Invoke-RestMethod -method 'GET' -uri ($Auvik_Base_URI + $resource_uri) -Headers $AuvikAPI_Headers -Body $qparams -ErrorAction SilentlyContinue
            } catch [System.Net.WebException] {
                $_.Exception.Response
            } catch {
                Write-Error $_
            } finally {
                $Null = $AuvikAPI_Headers.Remove('Authorization')
            }
            Write-Verbose "Status Code Returned: $([int]$rest_output.StatusCode)"
        } Until ($([int]$rest_output.StatusCode) -ne 502 -or $attempt -ge 5)
        $data += $rest_output
    }
}

End {
    Return $data
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

    If ($PSCmdlet.ParameterSetName -eq 'index') {
        $Id = @('')
        If ($Tenants) {
            $qparams += @{'tenants' = $Tenants -join ','}
        }
        If ($DeviceType) {
            $qparams += @{'filter[deviceType]' = $DeviceType}
        }
        If ($ModifiedAfter) {
            $qparams += @{'filter[modifiedAfter]' = $ModifiedAfter.ToString('yyyy-MM-ddTHH:mm:ss.fffzzz')}
        }
    }
    Else {
        #Parameter set "Show" is selected
    }

    ForEach ($deviceId IN $Id) {
        $resource_uri = ('/v1/inventory/device/detail/extended')
        If (!($Null -eq $deviceId) -and $deviceId -gt '') {
            $resource_uri = ('/v1/inventory/device/detail/extended/{0}' -f $deviceId)
        }

        $attempt=0
        Do {
            $attempt+=1
            If ($attempt -gt 1) {Start-Sleep 2}
            Write-Debug "Testing $($Auvik_Base_URI + $resource_uri)$(If ($qparams.Count -gt 0) {'?' + $(($qparams.GetEnumerator() | ForEach-Object {"$($_.Name)=$($_.Value)"}) -join '&') })"
            $rest_output = try {
                $Null = $AuvikAPI_Headers.Add("Authorization", "Basic $x_api_authorization")
                Invoke-RestMethod -method 'GET' -uri ($Auvik_Base_URI + $resource_uri) -Headers $AuvikAPI_Headers -Body $qparams -ErrorAction SilentlyContinue
            } catch [System.Net.WebException] {
                $_.Exception.Response
            } catch {
                Write-Error $_
            } finally {
                $Null = $AuvikAPI_Headers.Remove('Authorization')
            }
            Write-Verbose "Status Code Returned: $([int]$rest_output.StatusCode)"
        } Until ($([int]$rest_output.StatusCode) -ne 502 -or $attempt -ge 5)
        $data += $rest_output
    }
}

End {
    Return $data
}

}
