function Confirm-AuvikAPICredential {
    [CmdletBinding(DefaultParameterSetName = 'credential')]
    Param (
        [Parameter(ParameterSetName = 'userkey')]
        [String]$UserName = '',

        [Parameter(ParameterSetName = 'userkey')]
        [String]$API_Key = '',

        [Parameter(ParameterSetName = 'credential')]
        [PSCredential]$Credential = $Auvik_API_Credential,

        [Parameter(ParameterSetName = 'userkey')]
        [Parameter(ParameterSetName = 'credential')]
        [Switch]$Quiet
        )

	$x_api_authorization = $Null
    $resource_uri = ('/authentication/verify')

    if ($PSCmdlet.ParameterSetName -eq 'userkey') {
		if ($Api_Key) {
            $x_api_authorization = "$($Username):$($API_Key)"
        }
    } Else {
        $x_api_authorization = "$($Auvik_API_Credential.UserName):$([Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($Auvik_API_Credential.Password)))"
    }

    $data = @{}

    if ($x_api_authorization) {
        Write-Debug "Testing $x_api_authorization"
        $x_api_authorization = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($x_api_authorization))
        $attempt=0
        do {
            $attempt+=1
            if ($attempt -gt 1) {Start-Sleep 2}
            $AuvikAPI_Headers.Add("Authorization", "Basic $x_api_authorization")
            $rest_output = try {
                Invoke-WebRequest -method 'GET' -uri ($Auvik_Base_URI + $resource_uri) -Headers $AuvikAPI_Headers `
                                -ErrorAction SilentlyContinue
            } catch [System.Net.WebException] { 
                $_.Exception.Response 
            } finally {
                $Null = $AuvikAPI_Headers.Remove('Authorization')
            }
            Write-Verbose "Status Code Returned: $([int]$rest_output.StatusCode)"
        } until ($([int]$rest_output.StatusCode) -ne 502 -or $attempt -ge 5)
        if ([int]$rest_output.StatusCode -ne 200) {
            If (!$Quiet) {
                Write-Error "Authorization was not successful. Code Returned: $([int]$rest_output.StatusCode)"
            } Else { $rest_output = $False }
        } ElseIf ($Quiet) {
            $rest_output = $True
        }
        $data = $rest_output 
    } Else {
        Write-Error "No credentials were provided."
    }

    return $data
}
