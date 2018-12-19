function Add-AuvikBaseURI {
    [cmdletbinding()]
    Param (
        [parameter(ValueFromPipeline)]
        [Alias('Email')]
        [string]$BaseURI = 'https://auvikapi.us1.my.auvik.com',

        [Alias('locale','dc')]
        [ValidateSet( 'US', 'EU')]
        [String]$data_center = ''
    )

    # Trim superflous forward slash from address (if applicable)
    if($BaseURI[$BaseURI.Length-1] -eq "/") {
        $BaseURI = $BaseURI.Substring(0,$BaseURI.Length-1)
    }

    switch ($data_center) {
        'US' {$BaseURI = 'https://auvikapi.us1.my.auvik.com'}
        'EU' {$BaseURI = 'https://auvikapi.eu1.my.auvik.com'}
        Default {}
    }

    Set-Variable -Name "Auvik_Base_URI" -Value $BaseURI -Option ReadOnly -Scope global -Force
}

function Remove-AuvikBaseURI {
    Remove-Variable -Name "Auvik_Base_URI" -Scope global -Force 
}

function Get-AuvikBaseURI {
    return $Auvik_Base_URI
}

New-Alias -Name Set-AuvikBaseURI -Value Add-AuvikBaseURI