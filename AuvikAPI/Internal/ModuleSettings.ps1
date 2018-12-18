function Export-AuvikModuleSettings {

$secureString = $Auvik_API_KEY | ConvertFrom-SecureString 
$outputPath = "$($env:USERPROFILE)\AuvikAPI"
New-Item -ItemType Directory -Force -Path $outputPath | %{$_.Attributes = "hidden"}
@"
@{
    Auvik_Base_URI = '$Auvik_Base_URI'
    Auvik_User = '$Auvik_User'
    Auvik_API_Key = '$secureString'
    Auvik_JSON_Conversion_Depth = '$Auvik_JSON_Conversion_Depth'
}
"@ | Out-File -FilePath ($outputPath+"\config.psd1") -Force

}

function Import-AuvikModuleSettings {

    # PLEASE ADD ERROR CHECKING

    if(test-path "$($env:USERPROFILE)\AuvikAPI") {
        $tmp_config = Import-LocalizedData -BaseDirectory "$($env:USERPROFILE)\AuvikAPI" -FileName "config.psd1"

        # Send to function to strip potentially superflous slash (/)
        Add-AuvikBaseURI $tmp_config.Auvik_Base_URI

        $tmp_config.Auvik_API_key = ConvertTo-SecureString $tmp_config.Auvik_API_key

        Set-Variable -Name "Auvik_User"  -Value $tmp_config.Auvik_User `
                    -Option ReadOnly -Scope global -Force

		Set-Variable -Name "Auvik_API_Key"  -Value $tmp_config.Auvik_API_key `
                    -Option ReadOnly -Scope global -Force

		Set-Variable -Name "Auvik_API_Credential"  -Value (New-Object System.Management.Automation.PSCredential -ArgumentList $Auvik_User, $Auvik_API_Key) `
					-Option ReadOnly -Scope global -Force
						
        Set-Variable -Name "Auvik_JSON_Conversion_Depth" -Value $tmp_config.Auvik_JSON_Conversion_Depth `
                    -Scope global -Force 

        # Clean things up
        Remove-Variable "tmp_config","Auvik_User","Auvik_API_Key" -ErrorAction SilentlyContinue

        Write-Host "Module configuration loaded successfully!" -ForegroundColor Green
    }
    else {
        Write-Host "No configuration file was found." -ForegroundColor Red
        
        Set-Variable -Name "Auvik_Base_URI" -Value "https://auvikapi.us1.my.auvik.com"  -Option ReadOnly -Scope global -Force
        
        Write-Host "Using https://auvikapi.us1.my.auvik.com as Base URI. Run Add-AuvikBaseURI to modify."
        Write-Host "Please run Add-AuvikAPICredential to get started." -ForegroundColor Red
        
        Set-Variable -Name "Auvik_JSON_Conversion_Depth" -Value 100  -Scope global -Force
    }
}