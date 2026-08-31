$here = "d:\_PubCodes\mal\impls\batch"
$cases = @(
  @{ name="sumdown-def"; lines=@("(def! sumdown (fn* (N) (if (> N 0) (+ N (sumdown (- N 1))) 0)))") },
  @{ name="sumdown0"; lines=@("(def! sumdown (fn* (N) (if (> N 0) (+ N (sumdown (- N 1))) 0)))","(sumdown 0)") },
  @{ name="sumdown1"; lines=@("(def! sumdown (fn* (N) (if (> N 0) (+ N (sumdown (- N 1))) 0)))","(sumdown 1)") },
  @{ name="rec-simple"; lines=@("(def! r (fn* (n) (if (> n 0) (r (- n 1)) 0)))","(r 1)") },
  @{ name="rec-2"; lines=@("(def! r (fn* (n) (if (> n 0) (r (- n 1)) 0)))","(r 2)") }
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
  if(-not $p.WaitForExit(25000)){
    $p.Kill()
    Write-Output ("== {0,-14} -> TIMEOUT" -f $c.name)
    continue
  }
  $o = $out.Trim()
  $e = $err.Trim()
  Write-Output ("== {0,-14} -> rc={1} out=[{2}] err=[{3}]" -f $c.name, $p.ExitCode, ($o -replace "`r?`n"," | "), $e)
}
