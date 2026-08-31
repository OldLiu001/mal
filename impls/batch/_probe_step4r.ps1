$here = "d:\_PubCodes\mal\impls\batch"
$dbgfile = Join-Path $here "_dbg_out.txt"
if(Test-Path $dbgfile){ Remove-Item $dbgfile }
$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = "cmd.exe"
$psi.Arguments = "/c set _G.DBG=1 && step4_if_fn_do.bat READALL 2>_dbg_out.txt"
$psi.WorkingDirectory = $here
$psi.UseShellExecute = $false
$psi.RedirectStandardInput = $true
$psi.RedirectStandardOutput = $true
$psi.RedirectStandardError = $true
$p = [System.Diagnostics.Process]::Start($psi)
$p.StandardInput.WriteLine("(def! sumdown (fn* (N) (if (> N 0) (+ N (sumdown (- N 1))) 0)))")
$p.StandardInput.WriteLine("(sumdown 1)")
$p.StandardInput.Close()
$out = $p.StandardOutput.ReadToEnd()
$err = $p.StandardError.ReadToEnd()
if(-not $p.WaitForExit(8000)){
  $p.Kill()
  Write-Output "TIMEOUT"
} else {
  Write-Output ("RC=" + $p.ExitCode)
}
Write-Output ("OUT=[" + $out.Trim() + "]")
Write-Output "--- DBG ---"
if(Test-Path $dbgfile){ Get-Content $dbgfile | Select-Object -First 30 }
