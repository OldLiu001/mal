$ErrorActionPreference = 'SilentlyContinue'
$out = 'd:\_PubCodes\mal\_disk_win_special.txt'
"===== WIN SPECIAL $(Get-Date) =====" | Out-File $out -Encoding utf8
function Add-Result($lines) { Add-Content $out -Value $lines -Encoding utf8 }

Add-Result "--- System-level files on C:\ ---"
Get-ChildItem -LiteralPath 'C:\' -Force -File | ForEach-Object {
    if ($_.Length -ge 100MB) {
        $sz = if ($_.Length -ge 1GB) { "{0:N2} GB" -f ($_.Length/1GB) } else { "{0:N1} MB" -f ($_.Length/1MB) }
        Add-Result ("{0,-12} {1}" -f $sz, $_.FullName)
    }
}

Add-Result ""
Add-Result "--- C:\Windows\Temp ---"
if (Test-Path 'C:\Windows\Temp') {
    $t = (Get-ChildItem -LiteralPath 'C:\Windows\Temp' -Recurse -Force -File | Measure-Object -Property Length -Sum).Sum
    Add-Result ("   Total size: {0:N2} GB" -f ($t/1GB))
    Get-ChildItem -LiteralPath 'C:\Windows\Temp' -Recurse -Force -File | Sort-Object Length -Descending | Select-Object -First 15 | ForEach-Object {
        $sz = if ($_.Length -ge 1GB) { "{0:N2} GB" -f ($_.Length/1GB) } else { "{0:N1} MB" -f ($_.Length/1MB) }
        Add-Result ("   {0,-12} {1}" -f $sz, $_.FullName)
    }
}

Add-Result ""
Add-Result "--- C:\Windows\SoftwareDistribution ---"
if (Test-Path 'C:\Windows\SoftwareDistribution') {
    $t = (Get-ChildItem -LiteralPath 'C:\Windows\SoftwareDistribution' -Recurse -Force -File | Measure-Object -Property Length -Sum).Sum
    Add-Result ("   Total size: {0:N2} GB" -f ($t/1GB))
    Get-ChildItem -LiteralPath 'C:\Windows\SoftwareDistribution' -Recurse -Force -File | Sort-Object Length -Descending | Select-Object -First 15 | ForEach-Object {
        $sz = if ($_.Length -ge 1GB) { "{0:N2} GB" -f ($_.Length/1GB) } else { "{0:N1} MB" -f ($_.Length/1MB) }
        Add-Result ("   {0,-12} {1}" -f $sz, $_.FullName)
    }
}

Add-Result ""
Add-Result "--- C:\Windows\WinSxS ---"
if (Test-Path 'C:\Windows\WinSxS') {
    $t = (Get-ChildItem -LiteralPath 'C:\Windows\WinSxS' -Recurse -Force -File | Measure-Object -Property Length -Sum).Sum
    Add-Result ("   Total size: {0:N2} GB" -f ($t/1GB))
    Add-Result ("   (WinSxS 冗余清理应使用 DISM /StartComponentCleanup，勿手动删)")
}

Add-Result ""
Add-Result "--- Windows crash dumps ---"
$dumpRoots = @('C:\Windows\Minidump','C:\Windows\MEMORY.DMP','C:\Windows\LiveKernelReports','C:\Windows\System32')
foreach ($d in $dumpRoots) {
    if (Test-Path $d -PathType Container) {
        Get-ChildItem -LiteralPath $d -Recurse -Force -File -Include *.dmp 2>$null | Where-Object Length -ge 10MB | ForEach-Object {
            $sz = if ($_.Length -ge 1GB) { "{0:N2} GB" -f ($_.Length/1GB) } else { "{0:N1} MB" -f ($_.Length/1MB) }
            Add-Result ("   {0,-12} {1}" -f $sz, $_.FullName)
        }
    }
}
foreach ($d in @('C:\Windows\MEMORY.DMP','C:\Windows\System32\memchk.dmp')) {
    if (Test-Path $d -PathType Leaf) {
        $it = Get-Item $d
        $sz = if ($it.Length -ge 1GB) { "{0:N2} GB" -f ($it.Length/1GB) } else { "{0:N1} MB" -f ($it.Length/1MB) }
        Add-Result ("   {0,-12} {1}" -f $sz, $it.FullName)
    }
}

Add-Result ""
Add-Result "--- pagefile / hiberfil ---"
foreach ($p in @('C:\pagefile.sys','C:\hiberfil.sys','C:\swapfile.sys')) {
    if (Test-Path $p) {
        $it = Get-Item -Force $p
        Add-Result ("   {0,-12} {1}" -f ("{0:N2} GB" -f ($it.Length/1GB)), $it.FullName)
    }
}

Add-Result "===== DONE ====="