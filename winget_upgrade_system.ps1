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

$packages | Where-Object {
    # Extract major & minor from current and available versions
    $curParts = ($_.Version -split '[^0-9]+' | Where-Object { $_ -match '^\d+$' })
    $newParts = ($_.Available -split '[^0-9]+' | Where-Object { $_ -match '^\d+$' })

    # Ensure we have at least two parts for comparison
    if ($curParts.Count -lt 2) { $curParts += 0 }
    if ($newParts.Count -lt 2) { $newParts += 0 }

    # Compare major (index 0) or minor (index 1)
    ($curParts[0] -ne $newParts[0]) -or ($curParts[1] -ne $newParts[1])
} | ForEach-Object {
    Write-Host "Upgrading $($_.Name) from $($_.Version) to $($_.Available)..." -ForegroundColor Yellow
    winget upgrade --id $_.Id --accept-source-agreements --accept-package-agreements
}
