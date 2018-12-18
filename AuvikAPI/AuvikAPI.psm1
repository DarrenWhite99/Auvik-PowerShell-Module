$AuvikAPI_Headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"   
$AuvikAPI_Headers.Add("Content-Type", 'application/vnd.api+json') 

Set-Variable -Name "AuvikAPI_Headers"  -Value $AuvikAPI_Headers -Scope global


Import-AuvikModuleSettings