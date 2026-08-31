$ErrorActionPreference = 'SilentlyContinue'
$out = 'd:\_PubCodes\mal\_disk_scan_result.txt'
"===== SCAN START $(Get-Date) =====" | Out-File $out -Encoding utf8

function Add-Result($lines) {
    Add-Content $out -Value $lines -Encoding utf8
}

$MIN_SIZE = 20MB   # 阈值：只统计 >=20MB 的单独文件，聚焦大文件并控制扫描输出

# 各目标根目录
$roots = @(
    'C:\Users\OldLi\AppData\Roaming',
    'C:\Users\OldLi\AppData\Local',
    'C:\Windows',
    'C:\Users\OldLi\OneDrive - chnu.edu.cn'
)

foreach ($root in $roots) {
    Add-Result ""
    Add-Result "########## ROOT: $root ##########"
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $files = @()
    Get-ChildItem -LiteralPath $root -Recurse -Force -File |
        Where-Object { $_.Length -ge $MIN_SIZE } |
        ForEach-Object {
            $files += [PSCustomObject]@{
                Path = $_.FullName
                Size = $_.Length
            }
        }
    $sw.Stop()
    Add-Result ("   [scan time: {0:N1}s, files>=20MB counted: {1}]" -f $sw.Elapsed.TotalSeconds, $files.Count)
    $sorted = $files | Sort-Object Size -Descending | Select-Object -First 40
    foreach ($f in $sorted) {
        $sz = if ($f.Size -ge 1GB) { "{0:N2} GB" -f ($f.Size/1GB) } else { "{0:N1} MB" -f ($f.Size/1MB) }
        Add-Result ("{0,-12} {1}" -f $sz, $f.Path)
    }
    $files = $null
    [GC]::Collect()
}

Add-Result ""
Add-Result "===== SCAN DONE $(Get-Date) ====="