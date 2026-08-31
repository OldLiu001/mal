$here = "d:\_PubCodes\mal\impls\batch"
$cases = @(
  @{ name="sumdown1"; lines=@("(def! sumdown (fn* (N) (if (> N 0) (+ N (sumdown (- N 1))) 0)))","(sumdown 1)") }
)
foreach($c in $cases){
  $psi = New-Object System.Diagnostics.ProcessStartInfo
  $psi.FileName = "cmd.exe"
  $psi.Arguments = "/c set _G.DBG=1 && step4_if_fn_do.bat READALL"
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
  if(-not $p.WaitForExit(20000)){
    $p.Kill()
    Write-Output ("== {0,-12} -> TIMEOUT" -f $c.name)
    continue
  }
  $o = $out.Trim()
  $e = $err.Trim()
  Write-Output ("== {0,-12} -> rc={1}" -f $c.name, $p.ExitCode)
  Write-Output ("    out=[{0}]" -f ($o -replace "`r?`n"," | "))
  if($e){ Write-Output ("    err=[{0}]" -f ($e -replace "`r?`n"," | ")) }
}
