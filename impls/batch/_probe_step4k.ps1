$here = "d:\_PubCodes\mal\impls\batch"
$cases = @(
  @{ name="gt"; lines=@("(> 2 1)") },
  @{ name="if-gt"; lines=@("(if (> 2 1) 7 8)") },
  @{ name="fn-if-gt"; lines=@("(def! f (fn* (N) (if (> N 0) N 0)))","(f 1)") },
  @{ name="fn-if-gt0"; lines=@("(def! f (fn* (N) (if (> N 0) N 0)))","(f 0)") },
  @{ name="fn-sub"; lines=@("(def! f (fn* (N) (- N 1)))","(f 5)") },
  @{ name="fn-if-sub"; lines=@("(def! f (fn* (N) (if (> N 0) (- N 1) 0)))","(f 5)") }
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
