function Get-AuvikInterfacesInfo {
    [CmdletBinding(DefaultParameterSetName = 'index')]
    Param (
        [Parameter(ParameterSetName = 'show')]
        [String[]]$Id,
 
        [Parameter(ParameterSetName = 'index')]
        [String[]]$Devices = '',

        [Parameter(ParameterSetName = 'index')]
        [ValidateSet('ethernet', 'wifi', 'bluetooth', 'cdma', 'coax', 'cpu', `
            'firewire', 'gsm', 'ieee8023AdLag', 'inferredWired', `
            'inferredWireless', 'linkAggregation', 'loopback', 'modem', `
            'wimax', 'optical', 'other', 'parallel', 'ppp', 'rs232', 'tunnel', `
            'unknown', 'usb', 'virtualBridge', 'virtualNic', 'virtualSwitch', `
            'vlan', 'distributedVirtualSwitch', 'interface')]
        [String]$InterfaceType = '',

        [Parameter(ParameterSetName = 'index')]
        [ValidateSet('online', 'offline', 'unreachable', 'testing', 'unknown', 'dormant', 'notPresent')]
        [String]$OperationalStatus = '',

        [Parameter(ParameterSetName = 'index')]
        [datetime]$ModifiedAfter,

        [Parameter(ParameterSetName = 'index')]
        [String[]]$Tenants = '',

        [Parameter(ParameterSetName = 'index')]
        [Nullable[Boolean]]$AdminStatus

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
        if ($InterfaceType) {
            $qparams += @{'filter[interfaceType]' = $InterfaceType}
        }
        if ($OperationalStatus) {
            $qparams += @{'filter[operationalStatus]' = $OperationalStatus}
        }
        if ($Null -ne $AdminStatus) {
            if ($AdminStatus -eq $True) {
                $qparams += @{'filter[adminStatus]' = 'true'}
            } else {
                $qparams += @{'filter[adminStatus]' = 'false'}
            }
        }
        if ($ModifiedAfter) {
            $qparams += @{'filter[modifiedAfter]' = $ModifiedAfter}
        }
    }
    else {
        #Parameter set "Show" is selected
        $Devices = @('')
    }

    foreach ($interfaceId IN $Id) {
        foreach ($DeviceId IN $Devices) {
            $resource_uri = ('/v1/inventory/interface/info')
            if (!($Null -eq $interfaceId) -and $interfaceId -gt '') {
                $resource_uri = ('/v1/inventory/interface/info/{0}' -f $interfaceId)
            } elseif (!($Null -eq $DeviceId) -and $DeviceId -gt '') {
                $qparams['filter[parentDevice]'] = $DeviceId
            } else {
                $Null = $qparams.Remove('filter[parentDevice]')
            }
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
            $data += $rest_output | Where-Object {$_.Data.ID -gt ''}
        }
    }
 }

End {
    return $data
}

}

