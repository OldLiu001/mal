[CmdletBinding()]
$here = "d:\_PubCodes\mal\impls\batch"
# feed two simple lines to readall and capture its output count
$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = "cmd.exe"
$psi.Arguments = "/c readall.bat RAW"
$psi.WorkingDirectory = $here
$psi.UseShellExecute = $false
$psi.RedirectStandardInput = $true
$psi.RedirectStandardOutput = $true
$psi.RedirectStandardError = $true
$p = [System.Diagnostics.Process]::Start($psi)
$p.StandardInput.WriteLine("hello")
$p.StandardInput.WriteLine("world")
$p.StandardInput.Close()
$out = $p.StandardOutput.ReadToEnd()
if(-not $p.WaitForExit(8000)){ $p.Kill(); Write-Output "TIMEOUT" } else { Write-Output "RC=$($p.ExitCode)" }
Write-Output "OUT=[$($out.Trim())]"