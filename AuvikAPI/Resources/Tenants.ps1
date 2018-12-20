function Get-AuvikTenants {
    
    $resource_uri = ('/v1/tenants')

    $data = @{}

    $x_api_authorization = "$($Auvik_API_Credential.UserName):$([Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($Auvik_API_Credential.Password)))"
    $x_api_authorization = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($x_api_authorization))

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
    } until ($([int]$rest_output.StatusCode) -ne 502 -or $attempt -ge 5)
    $data = $rest_output | Select-Object -ExpandProperty 'Data' -EA 0
    return $data
}
