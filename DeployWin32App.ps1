# Get and veeify the Datto RMM Site ID
Read-Host "Enter the Datto RMM Site ID" -OutVariable siteId
$siteId = $siteId.Trim()
$file = "$env:temp\AgentInstall.exe"
try {
    (New-Object System.Net.WebClient).DownloadFile("https://pinotage.centrastage.net/csm/profile/downloadAgent/$siteId", $file)
    if (-not (Test-Path $file)) {
        Write-Host "Failed to download the Datto RMM Agent setup file. Please make sure the site ID is correct and try again." -ForegroundColor Red
        exit 1
    } else {
        Get-ChildItem -Path $file | Remove-Item -Force
        Write-Host "Datto RMM Site ID is valid." -ForegroundColor Green
    }
} catch {
    Write-Host "Failed to download the Datto RMM Agent setup file. Please make sure the site ID is correct and try again." -ForegroundColor Red
    exit 1
}

# Variable Section
$displayName = "Datto RMM"
$description = "Datto RMM"
$publisher = "Datto Inc."
$installBehavior = "system"
$installCommandLine = "powershell -ExecutionPolicy Bypass -File install.ps1 $siteId"
$uninstallCommandLine = "powershell -ExecutionPolicy Bypass -File uninstall.ps1"
$companyPortalFeaturedApp = $true
$intuneWinFile = "C:\Users\s.huibers\Downloads\OneDrive_2024-12-25\Datto RMM\Output\install.intunewin"
$detectionScriptContent = @"
if (Get-Service CagService -ErrorAction SilentlyContinue) {
    Write-Output "Datto RMM Agent already installed on this device"
    exit 0
} else {
    Write-Output "Datto RMM Agent not installed on this device"
    exit 1
}
"@
$graphModules = @("Microsoft.Graph.Authentication", "Microsoft.Graph.Applications", "Microsoft.Graph.Identity.DirectoryManagement")
$graphScopes = @("Application.ReadWrite.All", "Directory.ReadWrite.All", "AppRoleAssignment.ReadWrite.All", "RoleAssignmentSchedule.ReadWrite.Directory", "Domain.Read.All", "Domain.ReadWrite.All", "Directory.Read.All", "Policy.ReadWrite.ConditionalAccess", "DeviceManagementApps.ReadWrite.All", "DeviceManagementConfiguration.ReadWrite.All", "DeviceManagementManagedDevices.ReadWrite.All")
$entraAppName = "IntuneWin32App"

function Install-GraphdModule {
    param(
        [string]$moduleName
    )
    $currentVersion = (Get-Module -ListAvailable -Name $moduleName).Version
    if (-not $currentVersion) {
        Write-Host "Module $moduleName not found. Installing..." -ForegroundColor Yellow
        Install-Module -Name $moduleName -Force -Scope CurrentUser
        Write-Host "Module $moduleName installed successfully." -ForegroundColor Green
    }
    else {
        $latestVersion = (Find-Module -Name $moduleName).Version
        if ($latestVersion -gt $currentVersion) {
            Write-Host "A newer version of the $moduleName module is available. Updating the module..." -ForegroundColor Yellow
            Install-Module -Name $moduleName -Force
            Write-Host "Module $moduleName updated successfully." -ForegroundColor Green
        }
    }
}

function New-EntraApplication {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$AppName
    )
    try {
        # Define Microsoft Graph permissions
        $permissions = @(
            "DeviceManagementApps.ReadWrite.All",
            "DeviceManagementConfiguration.ReadWrite.All",
            "DeviceManagementManagedDevices.ReadWrite.All",
            "Directory.Read.All",
            "Group.ReadWrite.All",
            "DeviceManagementRBAC.Read.All",
            "DeviceManagementRBAC.ReadWrite.All",
            "Application.ReadWrite.All"
        )
        $mgServicePrincipal = Get-MgServicePrincipal -Filter "appId eq '00000003-0000-0000-c000-000000000000'"
        $requiredResourceAccess = @{
            ResourceAppId = $mgServicePrincipal.AppId
            ResourceAccess = $permissions | ForEach-Object {
                @{
                    Id = ($mgServicePrincipal.AppRoles | Where-Object Value -eq $_).Id
                    Type = "Role"
                }
            }
        }

        # Create the application
        $params = @{
            DisplayName = $appName
            SignInAudience = "AzureADMyOrg"
            RequiredResourceAccess = $requiredResourceAccess
            Web = @{
                RedirectUris = @("https://login.microsoftonline.com/common/oauth2/nativeclient")
            }
        }
        $entraApplication = New-MgApplication @params

        # Create service principal
        $appServicePrincipal = New-MgServicePrincipal -AppId $entraApplication.AppId

        # Create client secret
        $secretEndDate = (Get-Date).AddDays(1)
        $passwordCred = @{
            displayName = "Temporary Secret"
            endDateTime = $secretEndDate
        }
        $secret = Add-MgApplicationPassword -ApplicationId $entraApplication.Id -PasswordCredential $passwordCred

        # Get tenant details
        $tenantId = (Get-MgContext).TenantId

        # Automatically grant admin consent
        foreach ($resource in $requiredResourceAccess) {
            foreach ($permission in $resource.ResourceAccess) {
                if ($permission.Type -eq "Role") {
                    try {
                        $appRoleAssignment = @{
                            PrincipalId = $appServicePrincipal.Id
                            ResourceId = $mgServicePrincipal.Id
                            AppRoleId = $permission.Id
                        }

                        New-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $appServicePrincipal.Id -BodyParameter $appRoleAssignment | Out-Null
                    }
                    catch {
                        Write-Host "Error granting admin consent for the permission $($permission.Id): $($_.Exception.Message)" -ForegroundColor Red
                        exit 1
                    }
                }
            }
        }

        $returnValue = [PSCustomObject]@{
            TenantId = $tenantId
            AppId = $entraApplication.AppId
            Secret = $secret.SecretText
        }
        return $returnValue
    }
    catch {
        Write-Host "Error creating the application: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}

# Clear the console
Clear-Host

# Install the required modules
foreach ($module in $graphModules) {
    Install-GraphdModule -moduleName $module
}

# Connect to Microsoft Graph
Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null
Connect-MgGraph -Scopes $graphScopes -NoWelcome
try {
    $tenantId = (Get-MgContext -ErrorAction Stop).TenantId
    $tenantDisplayName = (Get-MgOrganization -ErrorAction Stop).DisplayName
}
catch {
    Write-Host "Error connecting to Microsoft Graph: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Create the application
$entraApp = New-EntraApplication -AppName $entraAppName

#
# Connect to Intune Graph API
Connect-MSIntuneGraph -TenantID $entraApp.TenantId -ClientID $entraApp.AppId -ClientSecret $entraApp.Secret -ErrorAction Stop

# Create requirement rule for all platforms and Windows 10 20H2
$RequirementRule = New-IntuneWin32AppRequirementRule -Architecture "All" -MinimumSupportedWindowsRelease "W10_1607"

# Create PowerShell script detection rule
$scriptFile = "$env:temp\DetectionScriptContent.ps1"
$detectionScriptContent | Out-File -FilePath $scriptFile -Force -Encoding ascii
$detectionRule = New-IntuneWin32AppDetectionRuleScript -ScriptFile $scriptFile -EnforceSignatureCheck $false -RunAs32Bit $false
Get-ChildItem -Path $scriptFile | Remove-Item -Force

# Add new EXE Win32 app
$params = @{
    DisplayName = $displayName;
    Description = $description;
    Publisher = $publisher;
    InstallExperience = "system";
    RestartBehavior = "suppress";
    DetectionRule = $detectionRule;
    RequirementRule = $RequirementRule;
    InstallCommandLine = $installCommandLine;
    UninstallCommandLine = $uninstallCommandLine;
    Verbose = $true;
    FilePath = $intuneWinFile
}
Add-IntuneWin32App @params


# Remove the application
try {
    Remove-MgApplication -ApplicationId $entraApp.AppId -ErrorAction Stop
} catch {
    Write-Host "Error removing the application: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}