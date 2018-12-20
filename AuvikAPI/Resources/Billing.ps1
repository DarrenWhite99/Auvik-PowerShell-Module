function Get-AuvikBillingInfo {
    [CmdletBinding(DefaultParameterSetName = 'show')]
    Param (
        [Parameter(ParameterSetName = 'show')]
        [Alias('Tenant')]
        [String]$PrimaryTenant,
 
        [Parameter(ParameterSetName = 'show')]
        [String]$QueryTenant,
 
        [Parameter(ParameterSetName = 'show')]
        [ValidateSet('all', 'children')]
        [String]$Descendants = '',

        [Parameter(ParameterSetName = 'show')]
        [Alias('Date')]
        [datetime]$FromDate,

        [Parameter(ParameterSetName = 'show')]
        [datetime]$ToDate,

        [Parameter(ParameterSetName = 'show', Mandatory = $false)]
        [switch]$Daily=$False

    )

Begin {
    $data = @()
    $qparams = @{}
    $x_api_authorization = "$($Auvik_API_Credential.UserName):$([Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($Auvik_API_Credential.Password)))"
    $x_api_authorization = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($x_api_authorization))

    if (!($PrimaryTenant)) {
        $PrimaryTenant = Get-AuvikTenants | Select-Object -ExpandProperty attributes | Sort-Object -Property @{Expression={$_.tenantType -eq 'multiClient'}; Ascending=$False} | Select-Object -ExpandProperty domainprefix -First 1
    }
    if (!($PrimaryTenant)) {
        Write-Error "Failed to resolve Primary Tenant Name"
    }

    if ($PSCmdlet.ParameterSetName -eq 'show') {
        if ($QueryTenant) {
            $qparams += @{'tenant' = $QueryTenant}
        } else {
            $qparams += @{'tenant' = $PrimaryTenant}
        }
        if ($Descendants) {
            $qparams += @{'descendants' = $Descendants}
        }
        if (!($FromDate)) {
            if ($ToDate) {
                $FromDate = $ToDate
            } else {
                $FromDate=(Get-Date).AddDays(-1)
            }
        }
        $qparams += @{'from' = $FromDate.ToString('yyyy-MM-dd')}
        if ($ToDate) {
            $qparams += @{'to' = $FromDate.ToString('yyyy-MM-dd')}
        } else {
            if ($Daily -eq $True) {
                $qparams += @{'to' = ((Get-Date).AddDays(-1)).ToString('yyyy-MM-dd')}
            } else {
                $qparams += @{'to' = $FromDate.ToString('yyyy-MM-dd')}
            }
        }
        if ($Null -ne $Daily) {
            if ($Daily -eq $True) {
                $qparams += @{'daily' = 'true'}
            } else {
                $qparams += @{'daily' = 'false'}
            }
        }
    }
    else {
        #Unknown Parameter set is selected
    }

}

Process {

    $resource_uri = ('/api/billing/v1/summary')
    $x_Base_URI = $Auvik_Base_URI -replace '(?<=//)[^.]+',$PrimaryTenant

    if ($qparams.Count -gt 0) { $resource_uri += '?' + $(($qparams.GetEnumerator() | ForEach-Object {"$($_.Name)=$($_.Value)"}) -join '&') }

    $attempt=0
    do {
        $attempt+=1
        if ($attempt -gt 1) {Start-Sleep 2}
        $rest_output = try {
            $Null = $AuvikAPI_Headers.Add("Authorization", "Basic $x_api_authorization")
            Invoke-RestMethod -method 'GET' -uri ($x_Base_URI + $resource_uri) -Headers $AuvikAPI_Headers `
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
    $data += $rest_output 

}

End {
    return $data
}

}

function Get-AuvikBillingDetails {
    [CmdletBinding(DefaultParameterSetName = 'show')]
    Param (
        [Parameter(ParameterSetName = 'show')]
        [Alias('Tenant')]
        [String]$PrimaryTenant,
 
        [Parameter(ParameterSetName = 'show')]
        [String]$QueryTenant,
 
        [Parameter(ParameterSetName = 'show')]
        [ValidateSet('all', 'children')]
        [String]$Descendants = '',

        [Parameter(ParameterSetName = 'show')]
        [Alias('Date')]
        [datetime]$FromDate,

        [Parameter(ParameterSetName = 'show')]
        [datetime]$ToDate,

        [Parameter(ParameterSetName = 'show', Mandatory = $false)]
        [switch]$Daily=$False

    )

Begin {
    $data = @()
    $qparams = @{}
    $x_api_authorization = "$($Auvik_API_Credential.UserName):$([Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($Auvik_API_Credential.Password)))"
    $x_api_authorization = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($x_api_authorization))

    if (!($PrimaryTenant)) {
        $PrimaryTenant = Get-AuvikTenants | Select-Object -ExpandProperty attributes | Sort-Object -Property @{Expression={$_.tenantType -eq 'multiClient'}; Ascending=$False} | Select-Object -ExpandProperty domainprefix -First 1
    }
    if (!($PrimaryTenant)) {
        Write-Error "Failed to resolve Primary Tenant Name"
    }

    if ($PSCmdlet.ParameterSetName -eq 'show') {
        if ($QueryTenant) {
            $qparams += @{'tenant' = $QueryTenant}
        } else {
            $qparams += @{'tenant' = $PrimaryTenant}
        }
        if ($Descendants) {
            $qparams += @{'descendants' = $Descendants}
        }
        if (!($FromDate)) {
            if ($ToDate) {
                $FromDate = $ToDate
            } else {
                $FromDate=(Get-Date).AddDays(-1)
            }
        }
        $qparams += @{'from' = $FromDate.ToString('yyyy-MM-dd')}
        if ($ToDate) {
            $qparams += @{'to' = $FromDate.ToString('yyyy-MM-dd')}
        } else {
            if ($Daily -eq $True) {
                $qparams += @{'to' = ((Get-Date).AddDays(-1)).ToString('yyyy-MM-dd')}
            } else {
                $qparams += @{'to' = $FromDate.ToString('yyyy-MM-dd')}
            }
        }
        if ($Null -ne $Daily) {
            if ($Daily -eq $True) {
                $qparams += @{'daily' = 'true'}
            } else {
                $qparams += @{'daily' = 'false'}
            }
        }
    }
    else {
        #Unknown Parameter set is selected
    }

}

Process {

    $resource_uri = ('/api/billing/v1/details')
    $x_Base_URI = $Auvik_Base_URI -replace '(?<=//)[^.]+',$PrimaryTenant

    if ($qparams.Count -gt 0) { $resource_uri += '?' + $(($qparams.GetEnumerator() | ForEach-Object {"$($_.Name)=$($_.Value)"}) -join '&') }

    $attempt=0
    do {
        $attempt+=1
        if ($attempt -gt 1) {Start-Sleep 2}
        $rest_output = try {
            $Null = $AuvikAPI_Headers.Add("Authorization", "Basic $x_api_authorization")
            Invoke-RestMethod -method 'GET' -uri ($x_Base_URI + $resource_uri) -Headers $AuvikAPI_Headers `
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
    $data += $rest_output 

}

End {
    return $data
}

}
