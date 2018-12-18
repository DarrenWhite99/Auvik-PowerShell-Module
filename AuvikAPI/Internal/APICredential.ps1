function Add-AuvikAPICredential {
    [cmdletbinding()]
    Param (
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [AllowEmptyString()]
        [Alias('Email')]
        [string]$UserName,
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [AllowEmptyString()]
        [Alias('ApiKey')]
        [string]$Api_Key
    )

    if ($UserName) {
        Set-Variable -Name "Auvik_User"  -Value $UserName -Option ReadOnly -Scope global -Force
    }
    else {
        Write-Host "Please enter your Auvik User Email Address:"
        $UserName = Read-Host

        Set-Variable -Name "Auvik_User"  -Value $UserName -Option ReadOnly -Scope global -Force
    }

	if ($Api_Key) {
        $x_api_key = ConvertTo-SecureString $Api_Key -AsPlainText -Force 

        Set-Variable -Name "Auvik_API_Key"  -Value $x_api_key -Option ReadOnly -Scope global -Force
    }
    else {
        Write-Host "Please enter your API key:"
        $x_api_key = Read-Host -AsSecureString

        Set-Variable -Name "Auvik_API_Key"  -Value $x_api_key -Option ReadOnly -Scope global -Force
    }
	
	Set-Variable -Name "Auvik_API_Credential"  -Value (New-Object System.Management.Automation.PSCredential -ArgumentList $Auvik_User, $Auvik_API_Key) -Option ReadOnly -Scope global -Force
	
}

function Remove-AuvikAPICredential {
    Remove-Variable -Name "Auvik_User","Auvik_API_Key","Auvik_API_Credential"  -Force  
}

function Get-AuvikAPICredential {

    if($Auvik_API_Credential -eq $null) {
        Write-Error "No API credentials exists. Please run Add-AuvikAPICredential to add one."
    }
    else {
		$Auvik_API_Credential
    }
}

New-Alias -Name Set-AuvikAPICredential -Value Add-AuvikAPICredential
