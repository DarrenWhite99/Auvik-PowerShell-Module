function Get-AuvikDeviceConfiguration {
    [CmdletBinding(DefaultParameterSetName = 'index')]
    Param (
        [Parameter(ParameterSetName = 'show')]
        [String[]]$Id,
 
        [Parameter(ParameterSetName = 'index')]
        [String[]]$Devices = '',
 
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

    If ($PSCmdlet.ParameterSetName -eq 'index') {
        $Id = @('')
        If ($Tenants) {
            $qparams += @{'tenants' = $Tenants -join ','}
        }
        If ($BackupTimeAfter) {
            $qparams += @{'filter[backupTimeAfter]' = $BackupTimeAfter.ToString('yyyy-MM-ddTHH:mm:ss.fffzzz')}
        }
        If ($BackupTimeBefore) {
            $qparams += @{'filter[backupTimeBefore]' = $BackupTimeBefore.ToString('yyyy-MM-ddTHH:mm:ss.fffzzz')}
        }
        If ($Null -ne $IsRunning) {
            If ($IsRunning -eq $True) {
                $qparams += @{'filter[isRunning]' = 'true'}
            } Else {
                $qparams += @{'filter[isRunning]' = 'false'}
            }
        }
    }
    Else {
        #Parameter set "Show" is selected
        $Devices = @('')
    }

    ForEach ($configId IN $Id) {
        ForEach ($DeviceId IN $Devices) {
            $resource_uri = ('/v1/inventory/configuration')
            $qparams['page[first]'] = 100
            If (!($Null -eq $configID) -and $configId -gt '') {
                $resource_uri = ('/v1/inventory/configuration/{0}' -f $configId)
                $Null = $qparams.Remove('page[first]')
            } ElseIf (!($Null -eq $DeviceId) -and $DeviceId -gt '') {
                $qparams['filter[deviceId]'] = $DeviceId
            } Else {
                $Null = $qparams.Remove('filter[deviceId]')
            }

            Do {
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
                If ($rest_output.links.next) {$qparams['page[after]'] = $rest_output.links.next -replace '%..','' -replace '.*?pageafter=([^&]*).*',"`$1"}
                Write-Debug "Page after value is $($qparams['page[after]'])"
            } Until (!($rest_output.links.next) -or $rest_output.links.next -eq '' )
        }
    }
}

End {
    Return $data
}

}
