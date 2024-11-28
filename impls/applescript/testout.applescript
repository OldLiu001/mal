use framework "Foundation"
use scripting additions

set outputString to "这是一个不换行的输出示例。"
-- 获取标准输出的文件句柄
set stdoutHandle to current application's NSFileHandle's fileHandleWithStandardOutput
-- 写入标准输出
stdoutHandle's write:(outputString)
