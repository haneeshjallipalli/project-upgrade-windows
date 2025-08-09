winget upgrade
$packages = winget upgrade | Select-Object -Skip 1 | ForEach-Object {
    # Match columns: Name, Id, Version, Available
    if ($_ -match '^(?<Name>.+?)\s{2,}(?<Id>[^\s]+)\s{2,}(?<Version>[^\s]+)\s{2,}(?<Available>[^\s]+)') {
        [PSCustomObject]@{
            Name      = $matches.Name.Trim()
            Id        = $matches.Id
            Version   = $matches.Version
            Available = $matches.Available
        }
    }
}

# Split into included and excluded
$included = @()
$excluded = @()

foreach ($pkg in $packages) {
    $curParts = ($pkg.Version -split '[^0-9]+' | Where-Object { $_ -match '^\d+$' })
    $newParts = ($pkg.Available -split '[^0-9]+' | Where-Object { $_ -match '^\d+$' })

    if ($curParts.Count -lt 2) { $curParts += 0 }
    if ($newParts.Count -lt 2) { $newParts += 0 }

    if (($curParts[0] -ne $newParts[0]) -or ($curParts[1] -ne $newParts[1])) {
        $included += $pkg
    }
    else {
        $excluded += $pkg
    }
}

Write-Host "`n=== Included in Upgrade (Major/Minor change) ===" -ForegroundColor Green
$included | Format-Table Name, Version, Available

Write-Host "`n=== Excluded from Upgrade (Patch-only change) ===" -ForegroundColor Red
$excluded | Format-Table Name, Version, Available

#Uncomment below to actually run upgrades
 foreach ($pkg in $included) {
     Write-Host "Upgrading $($pkg.Name)..." -ForegroundColor Yellow
     winget upgrade --id $pkg.Id --accept-source-agreements --accept-package-agreements
 }
