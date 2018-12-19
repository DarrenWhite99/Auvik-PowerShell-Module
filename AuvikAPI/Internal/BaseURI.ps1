function Add-AuvikBaseURI {
    [cmdletbinding()]
    Param (
        [parameter(ValueFromPipeline)]
        [string]$Base_URI = 'https://auvikapi.us1.my.auvik.com',

        [Alias('locale','dc')]
        [ValidateSet( 'US', 'EU')]
        [String]$data_center = ''
    )

    # Trim superflous forward slash from address (if applicable)
    if($base_uri[$base_uri.Length-1] -eq "/") {
        $base_uri = $base_uri.Substring(0,$base_uri.Length-1)
    }

    switch ($data_center) {
        'US' {$base_uri = 'https://auvikapi.us1.my.auvik.com'}
        'EU' {$base_uri = 'https://auvikapi.eu1.my.auvik.com'}
        Default {}
    }

    Set-Variable -Name "Auvik_Base_URI" -Value $base_uri -Option ReadOnly -Scope global -Force
}

function Remove-AuvikBaseURI {
    Remove-Variable -Name "Auvik_Base_URI" -Scope global -Force 
}

function Get-AuvikBaseURI {
    return $Auvik_Base_URI
}

New-Alias -Name Set-AuvikBaseURI -Value Add-AuvikBaseURI