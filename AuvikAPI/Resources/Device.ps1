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

        [ValidateSet('discoveryStatus', 'components', 'connectedDevices', `
            'configurations', 'manageStatus', 'interfaces')]
        [String[]]$IncludeDetailFields = '',

        # The cursor ID after which device records will be returned as a page, available in the meta property.
        # Use the Limit parameter to control the size of the page returned.
        [Parameter(ParameterSetName = 'index')]
        [String]$After,

        # The cursor ID before which device records will be returned as a page, available in the meta property.
        # Use the Limit parameter to control the size of the page returned.
        [Parameter(ParameterSetName = 'index')]
        [String]$Before,

        # Controls how many devices are returned. If unspecified, the maximum number of devices returned is 100.
        # Can be supplied with the After or Before parameters, or by itself to generate an initial page of results.
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

    If ($PSCmdlet.ParameterSetName -like 'index') {
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
        If ($After) {
            $qparams += @{'page[after]' = $After}
            If ($Limit) {
                $qparams += @{'page[first]' = $Limit.ToString()}
            }
        } ElseIf ($Before) {
            $qparams += @{'page[before]' = $Before}
            If ($Limit) {
                $qparams += @{'page[last]' = $Limit.ToString()}
            }
        } ElseIf ($Limit) {
            $qparams += @{'page[first]' = $Limit.ToString()}
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

        If ($rest_output.links.next) {
            $null = $rest_output.links.next -match '%5Bafter%5D=([\w]*)'
            $rest_output.meta | Add-Member -MemberType NoteProperty -Name 'nextCursor' -Value $Matches[1]
        }
        If ($rest_output.links.prev) {
            $null = $rest_output.links.prev -match '%5Bbefore%5D=([\w]*)'
            $rest_output.meta | Add-Member -MemberType NoteProperty -Name 'prevCursor' -Value $Matches[1]
        }
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
        [Nullable[Boolean]]$ManagedStatus,

        # The cursor ID after which device records will be returned as a page, available in the meta property.
        # Use the Limit parameter to control the size of the page returned.
        [Parameter(ParameterSetName = 'index')]
        [String]$After,

        # The cursor ID before which device records will be returned as a page, available in the meta property.
        # Use the Limit parameter to control the size of the page returned.
        [Parameter(ParameterSetName = 'index')]
        [String]$Before,

        # Controls how many devices are returned. If unspecified, the maximum number of devices returned is 100.
        # Can be supplied with the After or Before parameters, or by itself to generate an initial page of results.
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
        If ($After) {
            $qparams += @{'page[after]' = $After}
            If ($Limit) {
                $qparams += @{'page[first]' = $Limit.ToString()}
            }
        } ElseIf ($Before) {
            $qparams += @{'page[before]' = $Before}
            If ($Limit) {
                $qparams += @{'page[last]' = $Limit.ToString()}
            }
        } ElseIf ($Limit) {
            $qparams += @{'page[first]' = $Limit.ToString()}
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

        If ($rest_output.links.next) {
            $null = $rest_output.links.next -match '%5Bafter%5D=([\w]*)'
            $rest_output.meta | Add-Member -MemberType NoteProperty -Name 'nextCursor' -Value $Matches[1]
        }
        If ($rest_output.links.prev) {
            $null = $rest_output.links.prev -match '%5Bbefore%5D=([\w]*)'
            $rest_output.meta | Add-Member -MemberType NoteProperty -Name 'prevCursor' -Value $Matches[1]
        }
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
        [String[]]$Tenants = '',

        # The cursor ID after which device records will be returned as a page, available in the meta property.
        # Use the Limit parameter to control the size of the page returned.
        [Parameter(ParameterSetName = 'index')]
        [String]$After,

        # The cursor ID before which device records will be returned as a page, available in the meta property.
        # Use the Limit parameter to control the size of the page returned.
        [Parameter(ParameterSetName = 'index')]
        [String]$Before,

        # Controls how many devices are returned. If unspecified, the maximum number of devices returned is 100.
        # Can be supplied with the After or Before parameters, or by itself to generate an initial page of results.
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
        If ($After) {
            $qparams += @{'page[after]' = $After}
            If ($Limit) {
                $qparams += @{'page[first]' = $Limit.ToString()}
            }
        } ElseIf ($Before) {
            $qparams += @{'page[before]' = $Before}
            If ($Limit) {
                $qparams += @{'page[last]' = $Limit.ToString()}
            }
        } ElseIf ($Limit) {
            $qparams += @{'page[first]' = $Limit.ToString()}
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

        If ($rest_output.links.next) {
            $null = $rest_output.links.next -match '%5Bafter%5D=([\w]*)'
            $rest_output.meta | Add-Member -MemberType NoteProperty -Name 'nextCursor' -Value $Matches[1]
        }
        If ($rest_output.links.prev) {
            $null = $rest_output.links.prev -match '%5Bbefore%5D=([\w]*)'
            $rest_output.meta | Add-Member -MemberType NoteProperty -Name 'prevCursor' -Value $Matches[1]
        }
        $data += $rest_output
    }
}

End {
    Return $data
}

}
