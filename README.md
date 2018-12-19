# Auvik-PowerShell-Module
PowerShell Wrapper for the Auvik API  

# Base Module Functions
### Add-AuvikBaseURI
Description: Set the URI for API access  
Options: -Base_URI [URL]  
Options: -DC [US/EU]  
### Get-AuvikBaseURI
Description: Returns the URI configured for the current session  
Options: None
### Remove-AuvikBaseURI
Description: Removes the URI from the current session  
Options: None

### Add-AuvikAPICredential
Description: Sets a credential for use in the current session  
Options: -UserName [Auvik Username] -ApiKey [User API Key]
### Get-AuvikAPICredential
Description: Returns the current session credential object  
Options: None  
### Remove-AuvikAPICredential
Description: Removes the credential from the current session  
Options: None  

### Export-AuvikModuleSettings
Description: Stores the current session Module Settings including URI and Credential for later use for the current user only.  
Options: None  
### Import-AuvikModuleSettings
Description: Loads previously exported settings.  
Options: None  

# Functions by Endpoint
## Credentials
### Confirm-AuvikAPICredential
Description: Test the current or provided credential to verify access. Returns the server response or True/False with -Quiet  
Options: -UserName [Auvik Username] -ApiKey [User API Key] | -Credential [Credential Object]  
Options: -Quiet  

## Tenants
### Get-AuvikTenants
Description: Returns the list of tenant IDs available for the current user  
Options: None  

## Device
### Get-AuvikDevicesInfo
Description: Returns Device Information  
Options: -ID [List of Device IDs] -IncludeDetailFields [Return Addition Detail for one or more of these fields: discoveryStatus, components, connectedDevices, configurations, manageStatus, interfaces]  
Options: -Tenants [List of Tenant IDs] -Networks [List of Network IDs]  
    -MakeModel [Match for Make/Model] -VendorName [Match for Vendor]  
    -ModifiedAfter [Datestamp for earliest record]  
    -IncludeDetailFields [discoveryStatus, components, connectedDevices, configurations, manageStatus, interfaces]  
    -Status [online, offline, unreachable, testing, unknown, dormant, notPresent, lowerLayerDown]  
    -DeviceType [unknown, switch, l3Switch, router, accessPoint, firewall, workstation, server, storage, printer, copier, hypervisor, multimedia, phone, tablet, handheld, virtualAppliance, bridge, controller, hub, modem, ups, module, loadBalancer, camera, telecommunications, packetProcessor, chassis, airConditioner, virtualMachine, pdu, ipPhone, backhaul, internetOfThings, voipSwitch, stack, backupDevice, timeClock, lightingDevice, audioVisual, securityAppliance, utm, alarm, buildingManagement, ipmi, thinAccessPoint, thinClient]  

### Get-AuvikDevicesDetails
Description: Returns Device Details  
Options: -ID [List of Device IDs]  
Options: -Tenants [List of Tenant IDs] -ManagedStatus [True/False/Null]  
    -SNMPDiscovery = [disabled, determining, notSupported, notAuthorized, authorizing, authorized, privileged]  
    -WMIDiscovery = [disabled, determining, notSupported, notAuthorized, authorizing, authorized, privileged]  
    -LoginDiscovery = [disabled, determining, notSupported, notAuthorized, authorizing, authorized, privileged]  
    -VMWareDiscovery = [disabled, determining, notSupported, notAuthorized, authorizing, authorized, privileged]  

### Get-AuvikDevicesExtendedDetails
Description: Returns Extended Device Information. Information varies by Device Type  
Options: -ID [List of Device IDs]  
Options: -Tenants [List of Tenant IDs] -ModifiedAfter [Datestamp for earliest record]  
    -DeviceType [unknown, switch, l3Switch, router, accessPoint, firewall, workstation, server, storage, printer, copier, hypervisor, multimedia, phone, tablet, handheld, virtualAppliance, bridge, controller, hub, modem, ups, module, loadBalancer, camera, telecommunications, packetProcessor, chassis, airConditioner, virtualMachine, pdu, ipPhone, backhaul, internetOfThings, voipSwitch, stack, backupDevice, timeClock, lightingDevice, audioVisual, securityAppliance, utm, alarm, buildingManagement, ipmi, thinAccessPoint, thinClient]  

## Network
**Coming Soon**

## Interface
**Coming Soon**

## Component
**Coming Soon**

## Entity
**Coming Soon**

## Configuration
### Get-AuvikDeviceConfiguration
Description: Returns information on device configurations.  
Options: -ID [Configuration ID]  
Options: -Tenants [List of Tenant IDs] -DeviceID [Device ID] -BackupTimeAfter [Datestamp for earliest backup] -BackupTimeBefore [Datestamp for latest backup] -IsRunning [True/False/Null]  
# Example
Return all tenants. Return managed devices for each and return device counts for each type of device.  
    Import-Module AuvikAPI
    if (Confirm-AuvikAPICredential -Quiet) {
        $AuvikTenants = Get-AuvikTenants | Where-Object {$_.attributes.tenantType -eq 'client'} 
        foreach ($tenant in $AuvikTenants) {
            $TenantDevices = Get-AuvikDevicesInfo -Tenant $tenant.ID -IncludeDetailFields manageStatus 
            $ManagedDeviceIDs = $TenantDevices | Select-Object -ExpandProperty 'Included' -ErrorAction SilentlyContinue | Where-Object {$_.attributes.manageStatus -eq 'true'} | Select-Object -ExpandProperty 'ID' -ErrorAction SilentlyContinue
            $ManagedDevices = $TenantDevices | Select-Object -ExpandProperty 'Data' -ErrorAction SilentlyContinue | Where-Object {$ManagedDeviceIDs -contains $_.ID}
            $ManagedDevicesGroup = $ManagedDevices | Select-Object -ExpandProperty Attributes -ErrorAction SilentlyContinue | Group-Object -Property deviceType -AsHashTable -ErrorAction SilentlyContinue
            if ($ManagedDevicesGroup) {
                Write-Output "Client: $($tenant.attributes.domainPrefix)"
                foreach ($deviceType in $ManagedDevicesGroup.Keys) {
                    Write-Output "$deviceType,$($ManagedDevicesGroup.$deviceType.Count)"
                }
            }
        }
    }
