param([int]$N = 9)
$here = "d:\_PubCodes\mal\impls\batch"
$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = "cmd.exe"
$psi.Arguments = "/c step4_if_fn_do.bat READALL"
$psi.WorkingDirectory = $here
$psi.UseShellExecute = $false
$psi.RedirectStandardInput = $true
$psi.RedirectStandardOutput = $true
$psi.RedirectStandardError = $true
$p = [System.Diagnostics.Process]::Start($psi)
for($i=1; $i -le $N; $i++){ $p.StandardInput.WriteLine("(+ 1 2)") }
$p.StandardInput.Close()
$out = $p.StandardOutput.ReadToEnd()
if(-not $p.WaitForExit(12000)){ $p.Kill(); Write-Output "N=$N-same TIMEOUT" } else { Write-Output ("N=$N-same RC=" + $p.ExitCode) }
$lines = $out -split "`n"
Write-Output ("OUT-LINES=" + $lines.Count + " [" + $out.Trim() + "]")
Write-Output ("LAST3=[" + (($lines | Select-Object -Last 3) -join "|") + "]")