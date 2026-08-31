param([int]$N = 9)
$here = "d:\_PubCodes\mal\impls\batch"
$errf = Join-Path $here "_rds.txt"
if(Test-Path $errf){ Remove-Item $errf }
$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = "cmd.exe"
$psi.Arguments = "/c set _G.DBG=1 && step4_if_fn_do.bat READALL 2>_rds.txt"
$psi.WorkingDirectory = $here
$psi.UseShellExecute = $false
$psi.RedirectStandardInput = $true
$psi.RedirectStandardOutput = $true
$psi.RedirectStandardError = $true
$p = [System.Diagnostics.Process]::Start($psi)
for($i=1;$i -le $N;$i++){ $p.StandardInput.WriteLine("(+ 1 2)") }
$p.StandardInput.Close()
$out = $p.StandardOutput.ReadToEnd()
if(-not $p.WaitForExit(11000)){ $p.Kill(); Write-Output "N=$N TIMEOUT" } else { Write-Output ("N=$N RC=" + $p.ExitCode) }
Write-Output ("STDOUT-lines=" + (($out -split "`n").Count) + " [" + $out.Trim() + "]")
Write-Output "=== rds ==="
if(Test-Path $errf){ Get-Content $errf }