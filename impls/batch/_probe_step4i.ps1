$here = "d:\_PubCodes\mal\impls\batch"
$cases = @(
  @{ name="closure-capture-global"; lines=@("(def! g 42)","(def! f (fn* () g))","(f)") },
  @{ name="closure-self-ref"; lines=@("(def! f (fn* () f))","(f)") },
  @{ name="closure-capture-param"; lines=@("(def! mk (fn* (x) (fn* () x)))","(def! h (mk 99))","(h)") },
  @{ name="let-closure-capture"; lines=@("(let* (x 3) (def! getx (fn* () x)))","(getx)") },
  @{ name="sumdown2"; lines=@("(def! sumdown (fn* (N) (if (> N 0) (+ N (sumdown (- N 1))) 0)))","(sumdown 1)") },
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
  if(-not $p.WaitForExit(60000)){
    $p.Kill()
    Write-Output ("== {0,-26} -> TIMEOUT" -f $c.name)
    continue
  }
  $o = $out.Trim()
  $e = $err.Trim()
  Write-Output ("== {0,-26} -> rc={1}" -f $c.name, $p.ExitCode)
  Write-Output ("    out=[{0}]" -f ($o -replace "`r?`n"," | "))
  if($e){ Write-Output ("    err=[{0}]" -f $e) }
}
