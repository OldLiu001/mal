param([string]$L1 = "(+ 1 2)", [string]$L2 = "(if true 7 8)")
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
$p.StandardInput.WriteLine($L1)
$p.StandardInput.WriteLine($L2)
$p.StandardInput.Close()
$out = $p.StandardOutput.ReadToEnd()
if(-not $p.WaitForExit(8000)){ $p.Kill(); Write-Output "TIMEOUT" } else { Write-Output ("RC=" + $p.ExitCode) }
Write-Output ("OUT=[" + $out.Trim() + "]")