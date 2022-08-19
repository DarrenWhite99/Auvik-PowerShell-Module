function Get-AuvikTenants {
    
    $resource_uri = ('/v1/tenants')

    $data = @{}

    $x_api_authorization = "$($Auvik_API_Credential.UserName):$([Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($Auvik_API_Credential.Password)))"
    $x_api_authorization = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($x_api_authorization))

    $attempt=0
    Do {
        $attempt+=1
        If ($attempt -gt 1) {Start-Sleep 2}
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
    } Until ($([int]$rest_output.StatusCode) -ne 502 -or $attempt -ge 5)
    $data = $rest_output | Select-Object -ExpandProperty 'Data' -EA 0
    Return $data
}

function Get-AuvikTenantsDetail {

    [CmdletBinding(DefaultParameterSetName = 'show')]
    Param (
        [Parameter(ParameterSetName = 'show')]
        [String[]]$Id,

        [Parameter(ParameterSetName = 'show')]
        [Alias('Tenant')]
        [String]$PrimaryTenant
    )

    Begin {
        $data = @()
        $qparams = @{}
        $x_api_authorization = "$($Auvik_API_Credential.UserName):$([Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($Auvik_API_Credential.Password)))"
        $x_api_authorization = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($x_api_authorization))

        If (!($PrimaryTenant)) {
            $PrimaryTenant = Get-AuvikTenants | Select-Object -ExpandProperty attributes | Sort-Object -Property @{Expression={$_.tenantType -eq 'multiClient' -and !($_.relationships)}; Ascending=$False} | Select-Object -ExpandProperty domainprefix -First 1
            Write-Debug "Primary Tenant detected as $PrimaryTenant"
        }
        If (!($PrimaryTenant)) {
            Write-Error "Failed to resolve Primary Tenant Name"
        }
    }

    Process {

        If ($PSCmdlet.ParameterSetName -eq 'show') {
            If(($ID).Count -eq 0) {$Id = @('')}
        }
#        Write-Debug "IDs: $($ID), has $(($ID).Count) members. @(,`$ID) has $(@(,$ID).Count) members."

        ForEach ($TenantId IN $Id) {
            $resource_uri = ('/v1/tenants/detail')
            $qparams['tenantDomainPrefix']=$PrimaryTenant
#            $qparams['page[first]'] = 100
            If (!($Null -eq $TenantID) -and $TenantId -gt '') {
                $resource_uri = $resource_uri + ('/{0}' -f $TenantId)
            }

            Do {
                $attempt=0
                Do {
                    $attempt+=1
                    If ($attempt -gt 1) {Start-Sleep 2}
                    Write-Debug "Testing $($Auvik_Base_URI + $resource_uri)$(If ($qparams.Count -gt 0) {'?' + $(($qparams.GetEnumerator() | ForEach-Object {"$($_.Name)=$($_.Value)"}) -join '&') })"
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
                } Until ($([int]$rest_output.StatusCode) -ne 502 -or $attempt -ge 5)
                $data += $rest_output | Where-Object {$_.Data.ID -gt ''} | Select-Object -ExpandProperty 'Data' -EA 0
#                If ($rest_output.links.next) {$qparams['page[after]'] = $rest_output.links.next -replace '%..','' -replace '.*?pageafter=([^&]*).*',"`$1"}
#                Write-Debug "Page after value is $($qparams['page[after]'])"
            } Until (!($rest_output.links.next) -or $rest_output.links.next -eq '' )
        }
    }

    End {
        Return $data
    }

}
