# Script: P2V_assign_profile.ps1
# Stand-alone utility to assign Plan2Value workgroups based on AD profile
# The script reuses the existing modules from P2V_UserMgmt_20.ps1

Add-Type -AssemblyName System.Windows.Forms

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

Import-Module "$scriptRoot/P2V_module/P2V_config.psd1" -Global -Verbose
Import-Module "$scriptRoot/P2V_module/P2V_include.psd1" -Global -Verbose
Import-Module "$scriptRoot/P2V_module/P2V_dialog_func.psd1" -Global -Verbose
Import-Module "$scriptRoot/P2V_module/P2V_AD_func.psd1" -Global -Verbose
Import-Module "$scriptRoot/P2V_module/P2V_PS_func.psd1" -Global -Verbose

P2V_init -root $scriptRoot

function Get-PSGroupList {
    param([hashtable]$tenant)
    $tenantURL = "$($tenant.ServerURL)/$($tenant.tenant)"
    $apiUrl    = "$tenantURL/PlanningSpace/api/v1/workgroups?include=users"
    Invoke-RestMethod -Uri $apiUrl -Method Get -Headers @{Authorization = "Basic $($tenant.base64AuthInfo)"}
}

function GetProfileFromAD {
    param([string]$xkey)
    $profiles   = @()
    $adGroups   = Get-ADPrincipalGroupMembership -Identity $xkey | Select -ExpandProperty Name
    $map        = Import-Csv $adgroupfile | Where-Object { $_.category -eq 'PROFILE' }
    foreach ($g in $adGroups) {
        $hit = $map | Where-Object { $_.ADgroup -eq $g }
        if ($hit) { $profiles += $hit.PSgroup }
    }
    $profiles | Select -Unique
}

#---- select AD user
if ((get_AD_user_GUI -title 'Select AD user' -ne 'OK') -or (-not $global:usr_sel)) {
    Write-Warning 'No user selected.'
    return
}
$user = $global:usr_sel
$guiResult = get_AD_user_GUI -title 'Select AD user'
Write-Host "get_AD_user_GUI returned: $guiResult"
Write-Host "`$global:usr_sel is: $($global:usr_sel | Out-String)"

if ($guiResult -ne 'OK') {
    Write-Warning 'No user selected.'
    return
}

$user = $global:usr_sel
if (-not $user) {
    Write-Warning "No user object found in `$global:usr_sel"
    return
}
Write-Host "Selected user object: $($user | Out-String)"

#---- determine profile from AD
$profiles = GetProfileFromAD -xkey $xkey
if (!$profiles) {
    Write-Warning 'No profile detected from AD. Please select manually.'
    $all = Import-Csv "$config_path/SEC20_profiles_workgroups.csv" | Select -ExpandProperty profile -Unique
    $sel = $all | Out-GridView -Title 'Select profile' -OutputMode Single
    if ($sel) { $profiles = @($sel) } else { return }
}

Write-Output "Profiles: $($profiles -join ', ')"

#---- build profile to group mapping
$profileGroups = @{}
Import-Csv "$config_path/SEC20_profiles_workgroups.csv" | ForEach-Object {
    $profileGroups[$_.profile] += @($_.groups)
}

#---- select tenants
$tenants = select_PS_tenants -multiple $true -all $false
foreach ($key in $tenants.Keys) {
    $t = $tenants[$key]
    $userEntry = P2V_get_userlist -tenant $t | Where-Object { $_.logOnId -eq $upn }
    if (!$userEntry) { Write-Warning "$upn not found in tenant $($t.tenant)"; continue }

    $groups  = Get-PSGroupList -tenant $t
    $gIndex  = @{}
    $groups  | ForEach-Object { $gIndex[$_.name] = $_.id }

    $update  = @{}
    foreach ($p in $profiles) {
        foreach ($wg in $profileGroups[$p]) {
            $gid = $gIndex[$wg]
            if ($gid) {
                if (-not $update.ContainsKey($gid)) { $update[$gid] = @() }
                $update[$gid] += [PSCustomObject]@{ op='add'; path="/users/$($userEntry.id)"; value='' }
            }
        }
    }

    if ($update.Count -gt 0) {
        $body = $update | ConvertTo-Json
        if ($update.Count -eq 1) { $body = "[ $body ]" }
        $body = [System.Text.Encoding]::UTF8.GetBytes($body)
        $apiUrl = "$($t.ServerURL)/$($t.tenant)/planningspace/api/v1/workgroups/bulk"
        Invoke-RestMethod -Uri $apiUrl -Method Patch -Headers @{Authorization="Basic $($t.base64AuthInfo)"} -Body $body -ContentType 'application/json'
        Write-Output "Updated tenant $($t.tenant)"
    } else {
        Write-Output "No groups to update for tenant $($t.tenant)"
    }
}
