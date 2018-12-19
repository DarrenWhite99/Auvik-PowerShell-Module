function Get-AuvikComponentsInfo {
    [CmdletBinding(DefaultParameterSetName = 'index')]
    Param (
        [Parameter(ParameterSetName = 'show')]
        [String[]]$Id,
 
        [Parameter(ParameterSetName = 'index')]
        [String[]]$Devices = '',

        [Parameter(ParameterSetName = 'index')]
        [String]$DeviceName = '',

        [Parameter(ParameterSetName = 'index')]
        [ValidateSet('ok','degraded','failed')]
        [String]$CurrentStatus = '',

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
        if ($DeviceName) {
            $qparams += @{'filter[deviceName]' = $DeviceName}
        }
        if ($CurrentStatus) {
            $qparams += @{'filter[currentStatus]' = $CurrentStatus}
        }
        if ($ModifiedAfter) {
            $qparams += @{'filter[modifiedAfter]' = $ModifiedAfter.ToString('yyyy-MM-ddTHH:mm:ss.fffzzz')}
        }
    }
    else {
        #Parameter set "Show" is selected
        $Devices = @('')
    }

    foreach ($componentId IN $Id) {
        foreach ($DeviceId IN $Devices) {
            $resource_uri = ('/v1/inventory/component/info')
            if (!($Null -eq $componentId) -and $componentId -gt '') {
                $resource_uri = ('/v1/inventory/component/info/{0}' -f $componentId)
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

