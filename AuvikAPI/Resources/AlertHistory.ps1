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
    If ($PSCmdlet.ParameterSetName -eq 'index') {
        $Id = @('')
        If ($Tenants) {
            $qparams += @{'tenants' = $Tenants -join ','}
        }
        If ($AlertSpecificationID) {
            $qparams += @{'filter[alertSpecificationId]' = $AlertSpecificationID}
        }
        If ($Severity) {
            $qparams += @{'filter[severity]' = $Severity}
        }
        If ($Status) {
            $qparams += @{'filter[status]' = $Status}
        }
        If ($Null -ne $Dismissed) {
            If ($Dismissed -eq $True) {
                $qparams += @{'filter[dismissed]' = 'true'}
            } Else {
                $qparams += @{'filter[dismissed]' = 'false'}
            }
        }
        If ($Null -ne $Dispatched) {
            If ($Dispatched -eq $True) {
                $qparams += @{'filter[dispatched]' = 'true'}
            } Else {
                $qparams += @{'filter[dispatched]' = 'false'}
            }
        }
        If ($DetectedAfter) {
            $qparams += @{'filter[detectedTimeAfter]' = $DetectedAfter.ToString('yyyy-MM-ddTHH:mm:ss.fffzzz')}
        }
        If ($DetectedBefore) {
            $qparams += @{'filter[detectedTimeBefore]' = $DetectedBefore.ToString('yyyy-MM-ddTHH:mm:ss.fffzzz')}
        }
    }
    Else {
        #Parameter set "Show" is selected
        $Entities = @('')
    }

    ForEach ($alertId IN $Id) {
        ForEach ($entityID IN $Entities) {
            $resource_uri = '/v1/alert/history/info'
            If (!($Null -eq $alertId) -and $alertId -gt '') {
                $resource_uri = ('/v1/alert/history/info/{0}' -f $alertId)
            } ElseIf (!($Null -eq $entityID) -and $entityID -gt '') {
                $qparams['filter[entityId]'] = $entityID
            } Else {
                $Null = $qparams.Remove('filter[entityId]')
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
}

End {
    Return $data
}

}
