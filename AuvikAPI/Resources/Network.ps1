function Get-AuvikNetworksInfo {
    [CmdletBinding(DefaultParameterSetName = 'index')]
    Param (
        [Parameter(ParameterSetName = 'show')]
        [String[]]$Id,
 
        [Parameter(ParameterSetName = 'index')]
        [String[]]$Devices = '',

        [Parameter(ParameterSetName = 'index')]
        [ValidateSet('routed', 'vlan', 'wifi', 'loopback', 'network', 'layer2', 'internet')]
        [String]$NetworkType = '',

        [Parameter(ParameterSetName = 'index')]
        [ValidateSet('true','false','notAllowed','unknown')]
        [String]$ScanStatus = '',

        [Parameter(ParameterSetName = 'index')]
        [datetime]$ModifiedAfter,

        [Parameter(ParameterSetName = 'index')]
        [String[]]$Tenants = '',

        [Parameter(ParameterSetName = 'show')]
        [Parameter(ParameterSetName = 'index')]
        [ValidateSet('scope', 'primaryCollector', 'secondaryCollectors', 'collectorSelection', 'excludedIpAddresses')]
        [String[]]$IncludeDetailFields = ''

    )

Begin {
    $data = @()
    $qparams = @{}
    $x_api_authorization = "$($Auvik_API_Credential.UserName):$([Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($Auvik_API_Credential.Password)))"
    $x_api_authorization = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($x_api_authorization))
}

Process {
    If ($IncludeDetailFields) {
        $qparams += @{'include' = 'networkDetail'; 'fields[networkDetail]' = $IncludeDetailFields -join ','}
    }

    If ($PSCmdlet.ParameterSetName -eq 'index') {
        $Id = @('')
        If ($Tenants) {
            $qparams += @{'tenants' = $Tenants -join ','}
        }
        If ($NetworkType) {
            $qparams += @{'filter[networkType]' = $NetworkType}
        }
        If ($ScanStatus) {
            $qparams += @{'filter[scanStatus]' = $ScanStatus}
        }
        If ($ModifiedAfter) {
            $qparams += @{'filter[modifiedAfter]' = $ModifiedAfter.ToString('yyyy-MM-ddTHH:mm:ss.fffzzz')}
        }
    }
    Else {
        #Parameter set "Show" is selected
        $Devices = @('')
    }

    ForEach ($networkId IN $Id) {
        ForEach ($DeviceId IN $Devices) {
            $resource_uri = ('/v1/inventory/network/info')
            If (!($Null -eq $networkId) -and $networkId -gt '') {
                $resource_uri = ('/v1/inventory/network/info/{0}' -f $networkId)
            } ElseIf (!($Null -eq $DeviceId) -and $DeviceId -gt '') {
                $qparams['filter[devices]'] = $DeviceId
            } Else {
                $Null = $qparams.Remove('filter[devices]')
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
            $data += $rest_output | Where-Object {$_.Data.ID -gt ''}
        }
    }
 }

End {
    Return $data
}

}

function Get-AuvikNetworksDetails {
    [CmdletBinding(DefaultParameterSetName = 'index')]
    Param (
        [Parameter(ParameterSetName = 'show')]
        [String[]]$Id,
 
        [Parameter(ParameterSetName = 'index')]
        [String[]]$Devices = '',

        [Parameter(ParameterSetName = 'index')]
        [ValidateSet('routed', 'vlan', 'wifi', 'loopback', 'network', 'layer2', 'internet')]
        [String]$NetworkType = '',

        [Parameter(ParameterSetName = 'index')]
        [ValidateSet('true','false','notAllowed','unknown')]
        [String]$ScanStatus = '',

        [Parameter(ParameterSetName = 'index')]
        [ValidateSet('private', 'public')]
        [String]$Scope = '',

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
        If ($NetworkType) {
            $qparams += @{'filter[networkType]' = $NetworkType}
        }
        If ($ScanStatus) {
            $qparams += @{'filter[scanStatus]' = $ScanStatus}
        }
        If ($Scope) {
            $qparams += @{'filter[scope]' = $Scope}
        }
        If ($ModifiedAfter) {
            $qparams += @{'filter[modifiedAfter]' = $ModifiedAfter.ToString('yyyy-MM-ddTHH:mm:ss.fffzzz')}
        }
    }
    Else {
        #Parameter set "Show" is selected
        $Devices = @('')
    }

    ForEach ($networkId IN $Id) {
        ForEach ($DeviceId IN $Devices) {
            $resource_uri = ('/v1/inventory/network/detail')
            If (!($Null -eq $networkId) -and $networkId -gt '') {
                $resource_uri = ('/v1/inventory/network/detail/{0}' -f $networkId)
            } ElseIf (!($Null -eq $DeviceId) -and $DeviceId -gt '') {
                $qparams['filter[devices]'] = $DeviceId
            } Else {
                $Null = $qparams.Remove('filter[devices]')
            }

            $attempt=0
            Do {
                $attempt+=1
                If ($attempt -gt 1) {Start-Sleep 2}
                Write-Debug "Testing $($Auvik_Base_URI + $resource_uri)$(If ($qparams.Count -gt 0) { $resource_uri += '?' + $(($qparams.GetEnumerator() | ForEach-Object {"$($_.Name)=$($_.Value)"}) -join '&') })"
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
            $data += $rest_output | Where-Object {$_.Data.ID -gt ''}
        }
    }
 }

End {
    Return $data
}

}

