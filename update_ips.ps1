# Update all IP addresses from old to new
$oldIP = "13.221.117.236"
$newIP = "54.227.101.30"

Write-Host "════════════════════════════════════════════════════════"
Write-Host "🔄 UPDATING ALL IP ADDRESSES" -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════════════════"
Write-Host ""
Write-Host "Old IP: $oldIP" -ForegroundColor Red
Write-Host "New IP: $newIP" -ForegroundColor Green
Write-Host ""

$fileTypes = @("*.sh", "*.md")
$count = 0

foreach ($pattern in $fileTypes) {
    $files = Get-ChildItem -Path . -Filter $pattern -Recurse -File | Where-Object { $_.FullName -notmatch "\.git" }
    
    foreach ($file in $files) {
        $content = Get-Content $file.FullName -Raw
        if ($content -match [regex]::Escape($oldIP)) {
            $newContent = $content -replace [regex]::Escape($oldIP), $newIP
            Set-Content -Path $file.FullName -Value $newContent -NoNewline
            Write-Host "✓ Updated: $($file.Name)" -ForegroundColor Green
            $count++
        }
    }
}

Write-Host ""
Write-Host "════════════════════════════════════════════════════════"
Write-Host "✅ Updated $count files" -ForegroundColor Green
Write-Host "════════════════════════════════════════════════════════"

