$here = "d:\_PubCodes\mal\impls\batch"
$dbgfile = Join-Path $here "_dbg_out.txt"
if(Test-Path $dbgfile){ Remove-Item $dbgfile }
$cases = @(
  @{ name="sumdown1"; lines=@("(def! sumdown (fn* (N) (if (> N 0) (+ N (sumdown (- N 1))) 0)))","(sumdown 1)") }
)
foreach($c in $cases){
  $psi = New-Object System.Diagnostics.ProcessStartInfo
  $psi.FileName = "cmd.exe"
  $psi.Arguments = "/c set _G.DBG=1 && step4_if_fn_do.bat READALL 2>_dbg_out.txt"
  $psi.WorkingDirectory = $here
  $psi.UseShellExecute = $false
  $psi.RedirectStandardInput = $true
  $psi.RedirectStandardOutput = $true
  $psi.RedirectStandardError = $true
  $p = [System.Diagnostics.Process]::Start($psi)
  foreach($l in $c.lines){ $p.StandardInput.WriteLine($l) }
  $p.StandardInput.Close()
  $out = $p.StandardOutput.ReadToEnd()
  $err = $p.StandardError.ReadToEnd()
  if(-not $p.WaitForExit(15000)){
    $p.Kill()
    Write-Output ("== {0,-12} -> TIMEOUT" -f $c.name)
  } else {
    Write-Output ("== {0,-12} -> rc={1} out=[{2}]" -f $c.name, $p.ExitCode, ($out.Trim() -replace "`r?`n"," | "))
  }
  if(Test-Path $dbgfile){
    Write-Output ("    dbg=[{0}]" -f ((Get-Content $dbgfile -Raw) -replace "`r?`n"," | "))
  }
}
