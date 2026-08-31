$here = "d:\_PubCodes\mal\impls\batch"
$lines = @(
 "(+ 1 2)","(if true 7 8)","(list 1 2 3)","(count (list 1 2 3))",
 "(= 2 1)","(> 2 1)","(< 1 2)","(>= 1 1)","(<= 1 2)",
 "(if false 7 8)","(list? (list))","(empty? (list))",
 "(let* (a 5) a)","((fn* (a b) (+ b a)) 3 4)",
 "(if (> (count (list 1 2 3)) 3) 89 78)"
)
$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = "cmd.exe"
$psi.Arguments = "/c step4_if_fn_do.bat READALL"
$psi.WorkingDirectory = $here
$psi.UseShellExecute = $false
$psi.RedirectStandardInput = $true
$psi.RedirectStandardOutput = $true
$psi.RedirectStandardError = $true
$p = [System.Diagnostics.Process]::Start($psi)
foreach($ln in $lines){ $p.StandardInput.WriteLine($ln) }
$p.StandardInput.Close()
$out = $p.StandardOutput.ReadToEnd()
if(-not $p.WaitForExit(12000)){ $p.Kill(); Write-Output "TIMEOUT" } else { Write-Output ("RC=" + $p.ExitCode) }
Write-Output ("OUT=[" + $out.Trim() + "]")