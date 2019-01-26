function Add-AuvikBaseURI {
    [CmdletBinding(DefaultParameterSetName = 'uri')]
    Param (
        [parameter(ParameterSetName = 'uri',ValueFromPipeline,Position=1)]
        [string]$BaseURI = 'https://auvikapi.us1.my.auvik.com',

        [Parameter(ParameterSetName = 'datacenter')]
        [Alias('locale','dc')]
        [ValidatePattern("(US|EU)\d?")]
        [String]$data_center
    )

    If ($PSCmdlet.ParameterSetName -eq 'uri') {
        # Trim superflous forward slash from address (if applicable)
        If ($BaseURI[$BaseURI.Length-1] -eq "/") {
            $BaseURI = $BaseURI.Substring(0,$BaseURI.Length-1)
        }
    } ElseIf ($PSCmdlet.ParameterSetName -eq 'datacenter') {
        Write-Verbose "Evaluating Datacenter parameter `"$($data_center)`""
        # Assume DataCenter #1 if not specified
        switch -regex ($data_center) {
            '^US$' {$BaseURI = 'https://auvikapi.us1.my.auvik.com'; Break}
            '^EU$' {$BaseURI = 'https://auvikapi.eu1.my.auvik.com'; Break}
            Default {$BaseURI = "https://auvikapi.$($data_center.ToLower()).my.auvik.com"}
        }
    }
    Write-Verbose "Assigning Auvik_Base_URI=`"$($BaseURI)`""
    Set-Variable -Name "Auvik_Base_URI" -Value $BaseURI -Option ReadOnly -Scope global -Force
}

function Remove-AuvikBaseURI {
    Remove-Variable -Name "Auvik_Base_URI" -Scope global -Force 
}

function Get-AuvikBaseURI {
    Return $Auvik_Base_URI
}

New-Alias -Name Set-AuvikBaseURI -Value Add-AuvikBaseURI