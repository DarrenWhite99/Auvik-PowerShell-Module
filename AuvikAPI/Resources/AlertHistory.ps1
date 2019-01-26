function Get-AuvikAlertsInfo {
    [CmdletBinding(DefaultParameterSetName = 'index')]
    Param (
        [Parameter(ParameterSetName = 'show')]
        [String[]]$Id,
 
        [Parameter(ParameterSetName = 'index')]
        [String]$AlertSpecificationID = '',

        [Parameter(ParameterSetName = 'index')]
        [ValidateSet('unknown','emergency','critical','warning','info')]
        [String]$Severity = '',

        [Parameter(ParameterSetName = 'index')]
        [ValidateSet('created', 'resolved', 'paused', 'unpaused')]
        [String]$Status = '',

        [Parameter(ParameterSetName = 'index')]
        [String[]]$Entities = '',

        [Parameter(ParameterSetName = 'index')]
        [Nullable[Boolean]]$Dismissed,

        [Parameter(ParameterSetName = 'index')]
        [Nullable[Boolean]]$Dispatched,

        [Parameter(ParameterSetName = 'index')]
        [datetime]$DetectedAfter,

        [Parameter(ParameterSetName = 'index')]
        [datetime]$DetectedBefore,

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
        if ($AlertSpecificationID) {
            $qparams += @{'filter[alertSpecificationId]' = $AlertSpecificationID}
        }
        if ($Severity) {
            $qparams += @{'filter[severity]' = $Severity}
        }
        if ($Status) {
            $qparams += @{'filter[status]' = $Status}
        }
        if ($Null -ne $Dismissed) {
            if ($Dismissed -eq $True) {
                $qparams += @{'filter[dismissed]' = 'true'}
            } else {
                $qparams += @{'filter[dismissed]' = 'false'}
            }
        }
        if ($Null -ne $Dispatched) {
            if ($Dispatched -eq $True) {
                $qparams += @{'filter[dispatched]' = 'true'}
            } else {
                $qparams += @{'filter[dispatched]' = 'false'}
            }
        }
        if ($DetectedAfter) {
            $qparams += @{'filter[detectedTimeAfter]' = $DetectedAfter.ToString('yyyy-MM-ddTHH:mm:ss.fffzzz')}
        }
        if ($DetectedBefore) {
            $qparams += @{'filter[detectedTimeBefore]' = $DetectedBefore.ToString('yyyy-MM-ddTHH:mm:ss.fffzzz')}
        }
    }
    else {
        #Parameter set "Show" is selected
        $Entities = @('')
    }

    foreach ($alertId IN $Id) {
        foreach ($entityID IN $Entities) {
            $resource_uri = '/v1/alert/history/info'
            if (!($Null -eq $alertId) -and $alertId -gt '') {
                $resource_uri = ('/v1/alert/history/info/{0}' -f $alertId)
            } elseif (!($Null -eq $entityID) -and $entityID -gt '') {
                $qparams['filter[entityId]'] = $entityID
            } else {
                $Null = $qparams.Remove('filter[entityId]')
            }

            $attempt=0
            do {
                $attempt+=1
                if ($attempt -gt 1) {Start-Sleep 2}
                Write-Debug "Testing $($Auvik_Base_URI + $resource_uri)$(if ($qparams.Count -gt 0) {'?' + $(($qparams.GetEnumerator() | ForEach-Object {"$($_.Name)=$($_.Value)"}) -join '&') })"
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
            } until ($([int]$rest_output.StatusCode) -ne 502 -or $attempt -ge 5)
            $data += $rest_output
        }
    }
}

End {
    return $data
}

}
