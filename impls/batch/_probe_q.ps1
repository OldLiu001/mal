param([string]$Form = "(+ 1 2)")
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
$p.StandardInput.WriteLine($Form)
$p.StandardInput.Close()
$out = $p.StandardOutput.ReadToEnd()
if(-not $p.WaitForExit(5000)){
  $p.Kill(); Write-Output "TIMEOUT"
} else { Write-Output ("RC=" + $p.ExitCode) }
Write-Output ("OUT=[" + $out.Trim() + "]")