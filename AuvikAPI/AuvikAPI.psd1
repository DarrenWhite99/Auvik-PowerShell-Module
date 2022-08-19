#
# Module manifest for module 'AuvikAPI'
#
# Created by: Darren White
#
#  Created on: 12/13/2018
#

@{

# Script module or binary module file associated with this manifest
RootModule = '.\AuvikAPI.psm1'

# Version number of this module.
# Follows https://semver.org Semantic Versioning 2.0.0
# Given a version number MAJOR.MINOR.PATCH, increment the:
# -- MAJOR version when you make incompatible API changes,
# -- MINOR version when you add functionality in a backwards-compatible manner, and
# -- PATCH version when you make backwards-compatible bug fixes.
ModuleVersion = '1.0.3'

# ID used to uniquely identify this module
#GUID = ''

# Author of this module
Author = 'Darren White'

# Company or vendor of this module
CompanyName = 'Auvik'

# Description of the functionality provided by this module
Description = 'This module provides a PowerShell wrapper for the Auvik API.'

# Copyright information of this module
Copyright = 'https://github.com/DarrenWhite99/Auvik-PowerShell-Module/blob/master/LICENSE'

# Minimum version of the Windows PowerShell engine required by this module
PowerShellVersion = '3.0'

# Name of the Windows PowerShell host required by this module
# PowerShellHostName = ''

# Minimum version of the Windows PowerShell host required by this module
# PowerShellHostVersion = ''

# Minimum version of the .NET Framework required by this module
# DotNetFrameworkVersion = ''

# Minimum version of the common language runtime (CLR) required by this module
# CLRVersion = ''

# Processor architecture (None, X86, Amd64) required by this module
# ProcessorArchitecture = ''

# Modules that must be imported into the global environment prior to importing this module
# RequiredModules = @()

# Assemblies that must be loaded prior to importing this module
# RequiredAssemblies = @()

# Script files (.ps1) that are run in the caller's environment prior to importing this module
# ScriptsToProcess = @()

# Type files (.ps1xml) to be loaded when importing this module
# TypesToProcess = @()

# Format files (.ps1xml) to be loaded when importing this module
# FormatsToProcess = @()

# Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
NestedModules = 'Internal/BaseURI.ps1',
                'Internal/APICredential.ps1',
                'Internal/ModuleSettings.ps1',
                'Resources/AlertHistory.ps1',
                'Resources/Authentication.ps1',
                'Resources/Billing.ps1',
                'Resources/Component.ps1',
                'Resources/Configuration.ps1',
                'Resources/Device.ps1',
                'Resources/Entity.ps1',
                'Resources/Interface.ps1',
                'Resources/MetaData.ps1',
                'Resources/Network.ps1',
                'Resources/Tenants.ps1'

# Functions to export from this module
FunctionsToExport = 'Add-AuvikAPICredential',
                    'Confirm-AuvikAPICredential',
                    'Get-AuvikAPICredential',
                    'Remove-AuvikAPICredential',

                    'Add-AuvikBaseURI',
                    'Get-AuvikBaseURI',
                    'Remove-AuvikBaseURI',

                    'Export-AuvikModuleSettings',
                    'Import-AuvikModuleSettings',

                    'Get-AuvikAlertsInfo',

                    'Get-AuvikBillingInfo',
                    'Get-AuvikBillingDetails',
                    
                    'Get-AuvikComponentsInfo',

                    'Get-AuvikDeviceConfiguration',

                    'Get-AuvikDevicesInfo',
                    'Get-AuvikDevicesDetails',
                    'Get-AuvikDevicesExtendedDetails',

                    'Get-AuvikEntityAudits',
                    'Get-AuvikEntityNotes',

                    'Get-AuvikInterfacesInfo',

                    'Get-AuvikMetaField',

                    'Get-AuvikNetworksInfo',
                    'Get-AuvikNetworksDetails',
                    
                    'Get-AuvikTenants',
                    'Get-AuvikTenantsDetail'

#FunctionsToExport = '*'

# Cmdlets to export from this module
CmdletsToExport = @()

# Variables to export from this module
VariablesToExport = '*'

# Aliases to export from this module
AliasesToExport = '*'

# List of all modules packaged with this module
# ModuleList = @()

# List of all files packaged with this module
# FileList = @()

# Private data to pass to the module specified in RootModule/ModuleToProcess
# PrivateData = ''

# HelpInfo URI of this module
HelpInfoURI = 'https://github.com/DarrenWhite99/Auvik-PowerShell-Module'

# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
# DefaultCommandPrefix = ''

}