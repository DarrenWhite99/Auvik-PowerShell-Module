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

    If ($PSCmdlet.ParameterSetName -eq 'index') {
        $Id = @('')
        If ($Tenants) {
            $qparams += @{'tenants' = $Tenants -join ','}
        }
        If ($DeviceName) {
            $qparams += @{'filter[deviceName]' = $DeviceName}
        }
        If ($CurrentStatus) {
            $qparams += @{'filter[currentStatus]' = $CurrentStatus}
        }
        If ($ModifiedAfter) {
            $qparams += @{'filter[modifiedAfter]' = $ModifiedAfter.ToString('yyyy-MM-ddTHH:mm:ss.fffzzz')}
        }
    }
    Else {
        #Parameter set "Show" is selected
        $Devices = @('')
    }

    ForEach ($componentId IN $Id) {
        ForEach ($DeviceId IN $Devices) {
            $resource_uri = ('/v1/inventory/component/info')
            If (!($Null -eq $componentId) -and $componentId -gt '') {
                $resource_uri = ('/v1/inventory/component/info/{0}' -f $componentId)
            } ElseIf (!($Null -eq $DeviceId) -and $DeviceId -gt '') {
                $qparams['filter[deviceId]'] = $DeviceId
            } Else {
                $Null = $qparams.Remove('filter[deviceId]')
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

