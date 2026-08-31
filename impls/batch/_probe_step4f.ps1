$here = "d:\_PubCodes\mal\impls\batch"
$forms = @(
  "(+ 1 2)",
  "(def! a 5)",
  "a",
  "( (fn* (a) a) 5)",
  "(def! f (fn* (a) a))",
  "(f 5)",
  "( (fn* (a b) (+ b a)) 3 4)",
  "( (fn* () 4) )",
  "( (fn* (f x) (f x)) (fn* (a) (+ 1 a)) 7)",
  "( ( (fn* (a) (fn* (b) (+ a b))) 5) 7)",
  "(do (prn 101))",
  "(do (prn 102) 7)",
  "(do (def! a 6) 7 (+ a 8))"
)
foreach($f in $forms){
  $psi = New-Object System.Diagnostics.ProcessStartInfo
  $psi.FileName = "cmd.exe"
  $psi.Arguments = "/c step4_if_fn_do.bat READALL"
  $psi.WorkingDirectory = $here
  $psi.UseShellExecute = $false
  $psi.RedirectStandardInput = $true
  $psi.RedirectStandardOutput = $true
  $psi.RedirectStandardError = $true
  $p = [System.Diagnostics.Process]::Start($psi)
  $p.StandardInput.WriteLine($f)
  $p.StandardInput.Close()
  $out = $p.StandardOutput.ReadToEnd()
  $err = $p.StandardError.ReadToEnd()
  if(-not $p.WaitForExit(60000)){
    $p.Kill()
    Write-Output ("== {0,-46} -> TIMEOUT" -f $f)
    continue
  }
  $o = $out.Trim()
  $e = $err.Trim()
  Write-Output ("== {0,-46} -> rc={1} out=[{2}] err=[{3}]" -f $f, $p.ExitCode, $o, $e)
}
