$here = "d:\_PubCodes\mal\impls\batch"
$cases = @(
  @{ name="sumdown1"; lines=@("(def! sumdown (fn* (N) (if (> N 0) (+ N (sumdown (- N 1))) 0)))","(sumdown 1)") },
  @{ name="sumdown0"; lines=@("(def! sumdown (fn* (N) (if (> N 0) (+ N (sumdown (- N 1))) 0)))","(sumdown 0)") },
  @{ name="fib1"; lines=@("(def! fib (fn* (N) (if (= N 0) 1 (if (= N 1) 1 (+ (fib (- N 1)) (fib (- N 2)))))))","(fib 1)") },
  @{ name="fib2"; lines=@("(def! fib (fn* (N) (if (= N 0) 1 (if (= N 1) 1 (+ (fib (- N 1)) (fib (- N 2)))))))","(fib 2)") }
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
    Write-Output ("== {0,-10} -> TIMEOUT" -f $c.name)
    continue
  }
  $o = $out.Trim()
  $e = $err.Trim()
  Write-Output ("== {0,-10} -> rc={1} out=[{2}] err=[{3}]" -f $c.name, $p.ExitCode, ($o -replace "`r?`n"," | "), $e)
}
