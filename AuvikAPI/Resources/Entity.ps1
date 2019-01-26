function Get-AuvikEntityAudits {
    [CmdletBinding(DefaultParameterSetName = 'index')]
    Param (
        [Parameter(ParameterSetName = 'show')]
        [String[]]$Id,
 
        [Parameter(ParameterSetName = 'index')]
        [String]$User = '',

        [Parameter(ParameterSetName = 'index')]
        [ValidateSet('unknown', 'tunnel', 'terminal')]
        [String]$Category = '',

        [Parameter(ParameterSetName = 'index')]
        [ValidateSet('unknown', 'initiated', 'created', 'closed', 'failed')]
        [String]$Status = '',

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
        if ($User) {
            $qparams += @{'filter[user]' = $User}
        }
        if ($Category) {
            $qparams += @{'filter[category]' = $Category}
        }
        if ($Status) {
            $qparams += @{'filter[status]' = $Status}
        }
        if ($ModifiedAfter) {
            $qparams += @{'filter[modifiedAfter]' = $ModifiedAfter.ToString('yyyy-MM-ddTHH:mm:ss.fffzzz')}
        }
    }
    else {
        #Parameter set "Show" is selected
    }

    foreach ($entityAuditId IN $Id) {
        $resource_uri = ('/v1/inventory/entity/audit')
        if (!($Null -eq $entityAuditId) -and $entityAuditId -gt '') {
            $resource_uri = ('/v1/inventory/entity/audit/{0}' -f $entityAuditId)
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
        $data += $rest_output | Where-Object {$_.Data.ID -gt ''}
    }
 }

End {
    return $data
}

}

function Get-AuvikEntityNotes {
    [CmdletBinding(DefaultParameterSetName = 'index')]
    Param (
        [Parameter(ParameterSetName = 'show')]
        [String[]]$Id,
 
        [Parameter(ParameterSetName = 'index')]
        [String[]]$Entities = '',

        [Parameter(ParameterSetName = 'index')]
        [String]$EntityName = '',

        [Parameter(ParameterSetName = 'index')]
        [String]$User = '',

        [Parameter(ParameterSetName = 'index')]
        [ValidateSet('root','device','network','interface')]
        [String]$Type = '',

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
        if ($EntityName) {
            $qparams += @{'filter[entityName]' = $EntityName}
        }
        if ($Type) {
            $qparams += @{'filter[entityType]' = $Type}
        }
        if ($User) {
            $qparams += @{'filter[lastModifiedBy]' = $User}
        }
        if ($ModifiedAfter) {
            $qparams += @{'filter[modifiedAfter]' = $ModifiedAfter.ToString('yyyy-MM-ddTHH:mm:ss.fffzzz')}
        }
    }
    else {
        #Parameter set "Show" is selected
        $Entities = @('')
    }

    foreach ($entityNoteId IN $Id) {
        foreach ($entityID IN $Entities) {
            $resource_uri = ('/v1/inventory/entity/note')
            if (!($Null -eq $entityNoteId) -and $entityNoteId -gt '') {
                $resource_uri = ('/v1/inventory/entity/note/{0}' -f $entityNoteId)
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
            $data += $rest_output | Where-Object {$_.Data.ID -gt ''}
        }
    }
 }

End {
    return $data
}

}

