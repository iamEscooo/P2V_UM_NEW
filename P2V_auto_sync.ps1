# P2V_auto_sync.ps1
# Non-interactive script to synchronize AD users with Plan2Value tenants
param(
    [string]$User,
    [string[]]$TenantFilter,
    [switch]$IncludeInactive,
    [switch]$WhatIf,
    [switch]$Verbose
)

if ($Verbose) { $VerbosePreference = 'Continue' }

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Import-Module "$scriptRoot/P2V_module/P2V_config.psd1" -Global -Verbose:$false
Import-Module "$scriptRoot/P2V_module/P2V_include.psd1" -Global -Verbose:$false
Import-Module "$scriptRoot/P2V_module/P2V_AD_func.psd1" -Global -Verbose:$false
Import-Module "$scriptRoot/P2V_module/P2V_PS_func.psd1" -Global -Verbose:$false

P2V_init -root $scriptRoot

function Get-PSConfiguredTenants {
    param([string[]]$Filter)
    $out = @{}
    Import-Csv $tenantfile | ForEach-Object {
        if (!$Filter -or $_.tenant -in $Filter) {
            $b=[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes(("{0}:{1}" -f $_.name,$_.API)))
            $ht = $_ | Select-Object *
            $ht | Add-Member -Name 'base64AuthInfo' -Value $b -MemberType NoteProperty
            $out[$_.tenant] = $ht
        }
    }
    $out
}

function Get-PSGroupList {
    param([hashtable]$Tenant)
    $tenantURL = "$($Tenant.ServerURL)/$($Tenant.tenant)"
    $apiUrl    = "$tenantURL/PlanningSpace/api/v1/workgroups?include=users"
    Invoke-RestMethod -Uri $apiUrl -Method Get -Headers @{Authorization = "Basic $($Tenant.base64AuthInfo)"}
}

function GetProfileFromAD {
    param([string]$XKey)
    # Translate AD group memberships to P2V profile names.  The mapping is read
    # from $adgroupfile automatically, no manual selection required.
    $adGroups = Get-ADPrincipalGroupMembership -Identity $XKey | Select-Object -ExpandProperty Name
    $map      = Import-Csv $adgroupfile | Where-Object { $_.category -eq 'PROFILE' }
    $profiles = foreach ($g in $adGroups) {
        ($map | Where-Object { $_.ADgroup -eq $g }).PSgroup
    }
    $profiles | Where-Object {$_} | Select-Object -Unique
}

function GetProfileGroupMap {
    $map = @{}
    Import-Csv "$config_path/SEC20_profiles_workgroups.csv" | ForEach-Object {
        $map[$_.profile] += @($_.groups)
    }
    $map
}

function Sync-UserProfile {
    param(
        [Microsoft.ActiveDirectory.Management.ADUser]$ADUser,
        [hashtable]$Tenants,
        [hashtable]$ProfileMap,
        [switch]$WhatIf
    )
    $profiles = GetProfileFromAD -XKey $ADUser.SamAccountName
    if (-not $profiles) { return }

    $results = @()
    foreach ($tenantKey in $Tenants.Keys) {
        $t = $Tenants[$tenantKey]
        $userEntry = P2V_get_userlist -tenant $t | Where-Object { $_.logOnId -eq $ADUser.UserPrincipalName }
        if (!$userEntry) {
            $results += [pscustomobject]@{username=$ADUser.SamAccountName;email=$ADUser.EmailAddress;profile=($profiles -join ';');tenant=$tenantKey;status='UserMissing'}
            continue
        }
        $groups = Get-PSGroupList -Tenant $t
        $gIndex = @{}
        $groups | ForEach-Object { $gIndex[$_.name] = $_.id }

        $update = @{}
        foreach ($p in $profiles) {
            foreach ($wg in $ProfileMap[$p]) {
                $gid = $gIndex[$wg]
                if ($gid) {
                    if (-not $update.ContainsKey($gid)) { $update[$gid] = @() }
                    $update[$gid] += [pscustomobject]@{ op='add'; path="/users/$($userEntry.id)"; value='' }
                }
            }
        }

        $status = 'NoChanges'
        if ($update.Count -gt 0) {
            $body = $update | ConvertTo-Json
            if ($update.Count -eq 1) { $body = "[ $body ]" }
            if (-not $WhatIf) {
                $apiUrl = "$($t.ServerURL)/$($t.tenant)/planningspace/api/v1/workgroups/bulk"
                Invoke-RestMethod -Uri $apiUrl -Method Patch -Headers @{Authorization="Basic $($t.base64AuthInfo)"} -Body ([System.Text.Encoding]::UTF8.GetBytes($body)) -ContentType 'application/json'
                $status = 'Synced'
            } else {
                Write-Verbose "Would PATCH tenant $tenantKey with body $body"
                $status = 'WhatIf'
            }
        }
        $results += [pscustomobject]@{username=$ADUser.SamAccountName;email=$ADUser.EmailAddress;profile=($profiles -join ';');tenant=$tenantKey;status=$status}
    }
    $results
}

P2V_header -app $MyInvocation.MyCommand -path $scriptRoot -description 'Automatic AD synchronization'

$tenants = Get-PSConfiguredTenants -Filter $TenantFilter
$profileMap = GetProfileGroupMap
$summary = @()

#--- select user -------------------------------------------------------------
if (-not $User) { $User = Read-Host 'Enter user x-key or search string' }
$adUser = get_AD_user -xkey $User
if (-not $adUser) { Write-Error 'User not found in AD'; exit }
Write-Output "User: $($adUser.displayName) [$($adUser.UserPrincipalName)]"

#--- derive profiles and workgroups ----------------------------------------
$profiles = GetProfileFromAD -XKey $adUser.SamAccountName
if (-not $profiles) { Write-Error 'No profile detected from AD groups'; exit }
Write-Output 'Detected profiles:'
$profiles | ForEach-Object { Write-Output " - $_" }

$workgroups = @()
foreach ($p in $profiles) { $workgroups += $profileMap[$p] }
$workgroups = $workgroups | Sort-Object -Unique

Write-Output 'Workgroups to be assigned:'
$workgroups | ForEach-Object { Write-Output " - $_" }

$cont = Read-Host 'Proceed with these workgroups? (y/N)'
if ($cont -notlike 'y*') { Write-Warning 'Aborted'; P2V_footer -app $MyInvocation.MyCommand; return }

#--- tenant selection -------------------------------------------------------
Write-Output 'Available tenants:'
$tenants.Keys | ForEach-Object { Write-Output " - $_" }
$sel = Read-Host 'Tenant(s) to sync (comma separated, blank=all)'
if ($sel) {
    $names = $sel -split ',' | ForEach-Object { $_.Trim() }
    $tenants = $tenants.GetEnumerator() | Where-Object { $names -contains $_.Key } | ForEach-Object { $ten = $_.Value; @{ ($_.Key) = $ten } } | ForEach-Object { $_ }
    $temp = @{}
    foreach ($h in $tenants) { $key = $h.Keys[0]; $temp[$key] = $h[$key] }
    $tenants = $temp
}

#--- sync -------------------------------------------------------------------
$res = Sync-UserProfile -ADUser $adUser -Tenants $tenants -ProfileMap $profileMap -WhatIf:$WhatIf
foreach ($r in $res) {
    $summary += $r
    Write-Log "[$($r.tenant)] $($r.username) -> $($r.status)"
}

$summaryFile = Join-Path $output_path_base ("sync_summary_{0:yyyyMMdd_HHmm}.csv" -f (Get-Date))
$summary | Export-Csv -Path $summaryFile -NoTypeInformation
Write-Output "Summary stored in $summaryFile"

P2V_footer -app $MyInvocation.MyCommand
