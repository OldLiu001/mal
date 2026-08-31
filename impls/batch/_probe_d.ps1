$here = "d:\_PubCodes\mal\impls\batch"
$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = "cmd.exe"
$psi.Arguments = "/c set _G.DBG=1 && step4_if_fn_do.bat READALL 2>_dbg2.txt"
$psi.WorkingDirectory = $here
$psi.UseShellExecute = $false
$psi.RedirectStandardInput = $true
$psi.RedirectStandardOutput = $true
$psi.RedirectStandardError = $true
$p = [System.Diagnostics.Process]::Start($psi)
$p.StandardInput.WriteLine("(if false 7 8)")
$p.StandardInput.Close()
$out = $p.StandardOutput.ReadToEnd()
if(-not $p.WaitForExit(6000)){
  $p.Kill(); Write-Output "TIMEOUT"
} else { Write-Output ("RC=" + $p.ExitCode) }
Write-Output ("OUT=[" + $out.Trim() + "]")
Write-Output "---DBG2---"
Start-Sleep 1
if(Test-Path (Join-Path $here "_dbg2.txt")){ Get-Content (Join-Path $here "_dbg2.txt") | Select-Object -First 15 }