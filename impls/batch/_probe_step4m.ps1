$here = "d:\_PubCodes\mal\impls\batch"
$cases = @(
  @{ name="rec1-debug"; lines=@("(def! DEBUG-EVAL true)","(def! r (fn* (n) (if (> n 0) (r (- n 1)) 0)))","(r 1)") }
)
foreach($c in $cases){
  $psi = New-Object System.Diagnostics.ProcessStartInfo
  $psi.FileName = "cmd.exe"
  $psi.Arguments = "/c step4_if_fn_do.bat READALL"
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
  if(-not $p.WaitForExit(30000)){
    $p.Kill()
    Write-Output ("== {0,-14} -> TIMEOUT" -f $c.name)
    continue
  }
  $o = $out.Trim()
  $e = $err.Trim()
  Write-Output ("== {0,-14} -> rc={1}" -f $c.name, $p.ExitCode)
  Write-Output ("    out=[{0}]" -f ($o -replace "`r?`n"," | "))
  if($e){ Write-Output ("    err=[{0}]" -f $e) }
}
