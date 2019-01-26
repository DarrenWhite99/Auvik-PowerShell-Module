function Get-AuvikMetaField {
    [CmdletBinding(DefaultParameterSetName = 'field')]
    Param (
        [Parameter(ParameterSetName = 'field',Mandatory=$True)]
        [String]$Endpoint,

        [Parameter(ParameterSetName = 'field',Mandatory=$True)]
        [String]$Field

        )

Begin {
    $data = @()
    $qparams = @{}
    $x_api_authorization = "$($Auvik_API_Credential.UserName):$([Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($Auvik_API_Credential.Password)))"
    $x_api_authorization = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($x_api_authorization))
}

Process {
    if ($PSCmdlet.ParameterSetName -eq 'field') {
        if ($Endpoint) {
            $qparams += @{'endpoint' = $Endpoint}
        }
        if ($Field) {
            $qparams += @{'field' = $Field}
        }
    }
    else {
    }

    $resource_uri = ('/v1/meta/field/info')

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

End {
    return $data
}

}
