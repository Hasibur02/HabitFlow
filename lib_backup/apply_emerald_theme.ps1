# HabitFlow - Emerald Luxury theme applier
# Run from the project root (C:\Users\Hasibur Rahman\habitflow)

$path = Join-Path (Get-Location) "lib\main.dart"

if (-not (Test-Path $path)) {
    Write-Host "lib\main.dart not found. Run this script from the habitflow project folder." -ForegroundColor Red
    exit 1
}

# Backup first
Copy-Item $path "$path.bak" -Force
Write-Host "Backup created: lib\main.dart.bak" -ForegroundColor Green

$c = [System.IO.File]::ReadAllText($path)

# ORDER MATTERS: the first three keep "Study" blue (before the global purple -> emerald swap).
$pairs = [ordered]@{
    "'color': const Color(0xFF6558E8),"                  = "'color': const Color(0xFF3F5BD9),"
    "return const Color(0xFF6558E8);"                    = "return const Color(0xFF3F5BD9);"
    "static const Color studyColor = Color(0xFF6558E8);" = "static const Color studyColor = Color(0xFF3F5BD9);"

    "0xFF6558E8" = "0xFF0F6B57"
    "0xFF29264A" = "0xFF10332B"
    "0xFF29234F" = "0xFF06241E"
    "0xFF5145A8" = "0xFF0C4A3C"
    "0xFF7569D8" = "0xFF14876B"
    "0xFF17152D" = "0xFF06241E"
    "0xFF28204F" = "0xFF0C4A3C"
    "0xFFB78AFF" = "0xFFE2B857"
    "0xFF9389F2" = "0xFF2FB38F"
    "0xFFC5BFF0" = "0xFFC9E8DB"
    "0xFFA9A3CA" = "0xFFA9CBBE"
    "0xFFF3F0FF" = "0xFFF4FAF6"
    "0xFFEAE4FF" = "0xFFDDF1E8"
    "0xFFEAE6F7" = "0xFFDCEBE3"
    "0xFF77728F" = "0xFF6B7F78"
    "0xFF85809B" = "0xFF7F918A"
    "0xFF9690AD" = "0xFF96A8A1"
}

foreach ($k in $pairs.Keys) {
    $count = ($c -split [regex]::Escape($k)).Count - 1
    $c = $c.Replace($k, $pairs[$k])
    Write-Host ("{0,3} x  {1}" -f $count, $k)
}

[System.IO.File]::WriteAllText($path, $c, (New-Object System.Text.UTF8Encoding($false)))

Write-Host ""
Write-Host "Done! Now run: flutter run   (or press R for hot restart)" -ForegroundColor Green
Write-Host "To undo: copy lib\main.dart.bak back over lib\main.dart" -ForegroundColor Yellow