function Get-AuvikDeviceConfiguration {
    [CmdletBinding(DefaultParameterSetName = 'index')]
    Param (
        [Parameter(ParameterSetName = 'show')]
        [String[]]$Id,
 
        [Parameter(ParameterSetName = 'index')]
        [String[]]$Devices,
 
        [Parameter(ParameterSetName = 'index')]
        [String[]]$Tenants = '',

        [Parameter(ParameterSetName = 'index')]
        [datetime]$BackupTimeAfter,

        [Parameter(ParameterSetName = 'index')]
        [datetime]$BackupTimeBefore,

        [Parameter(ParameterSetName = 'index')]
        [Nullable[Boolean]]$IsRunning

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
        if ($BackupTimeAfter) {
            $qparams += @{'filter[BackupTimeAfter]' = $BackupTimeAfter}
        }
        if ($BackupTimeBefore) {
            $qparams += @{'filter[BackupTimeBefore]' = $BackupTimeBefore}
        }
        if ($Null -ne $IsRunning) {
            if ($IsRunning -eq $True) {
                $qparams += @{'filter[isRunning]' = 'true'}
            } else {
                $qparams += @{'filter[isRunning]' = 'false'}
            }
        }
    }
    else {
        #Parameter set "Show" is selected
        $Devices = @('')
    }

    foreach ($configId IN $Id) {
        foreach ($DeviceId IN $Devices) {
            $resource_uri = ('/v1/inventory/configuration')
            if (!($Null -eq $configID) -and $configId -gt '') {
                $resource_uri = ('/v1/inventory/configuration/{0}' -f $configId)
            } elseif (!($Null -eq $DeviceId) -and $DeviceId -gt '') {
                $qparams['filter[deviceId]'] = $DeviceId
            } else {
                $Null = $qparams.Remove('filter[deviceId]')
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
