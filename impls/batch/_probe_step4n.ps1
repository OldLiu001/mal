$here = "d:\_PubCodes\mal\impls\batch"
$cases = @(
  @{ name="r-id"; lines=@("(def! r (fn* (n) n))","(r 1)") },
  @{ name="r-if1"; lines=@("(def! r (fn* (n) (if (> n 0) 1 0)))","(r 1)") },
  @{ name="r-if0"; lines=@("(def! r (fn* (n) (if (> n 0) 1 0)))","(r 0)") },
  @{ name="r-sub"; lines=@("(def! r (fn* (n) (- n 1)))","(r 1)") },
  @{ name="r-if-sub"; lines=@("(def! r (fn* (n) (if (> n 0) (- n 1) 0)))","(r 1)") }
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
  if(-not $p.WaitForExit(20000)){
    $p.Kill()
    Write-Output ("== {0,-12} -> TIMEOUT" -f $c.name)
    continue
  }
  $o = $out.Trim()
  $e = $err.Trim()
  Write-Output ("== {0,-12} -> rc={1} out=[{2}] err=[{3}]" -f $c.name, $p.ExitCode, ($o -replace "`r?`n"," | "), $e)
}
