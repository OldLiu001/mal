on run argv
try
-- 检查是否有足够的参数
if (count of argv) < 2 then
error "Not enough arguments provided."
end if

-- 获取命令行参数
set firstArg to item 1 of argv
set secondArg to item 2 of argv

-- 输出参数
display dialog "First argument: " & firstArg
display dialog "Second argument: " & secondArg

on error errMsg number errNum
-- 处理错误
display dialog "Error: " & errMsg 
end try
end run
