$here = "d:\_PubCodes\mal\impls\batch"
$cases = @(
  @{ name="if-tests"; lines=@("(if true 7 8)","(if false 7 8)","(if false 7 false)","(if true (+ 1 7) (+ 1 8))","(if nil 7 8)","(if 0 7 8)","(if (list) 7 8)","(if false (+ 1 7))","(if nil 8)","(if nil 8 7)") },
  @{ name="eq-tests"; lines=@("(= 2 1)","(= 1 1)","(= nil nil)","(> 2 1)","(> 1 1)","(>= 1 1)","(< 1 2)","(<= 1 1)","(= (list) (list))","(= (list 1 2) (list 1 2))") },
  @{ name="list-tests"; lines=@("(list)","(list? (list))","(list? nil)","(empty? (list))","(empty? (list 1))","(list 1 2 3)","(count (list 1 2 3))","(count nil)") },
  @{ name="let-simple"; lines=@("(let* (x 5) x)","(let* (x 5 y 6) (+ x y))","(let* (x 5) (let* (y 9) (+ x y)))") }
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
    Write-Output ("== {0,-20} -> TIMEOUT" -f $c.name)
    continue
  }
  $o = $out.Trim()
  $e = $err.Trim()
  Write-Output ("== {0,-20} -> rc={1}" -f $c.name, $p.ExitCode)
  Write-Output ("    out=[{0}]" -f ($o -replace "`r?`n"," | "))
  if($e){ Write-Output ("    err=[{0}]" -f $e) }
}
