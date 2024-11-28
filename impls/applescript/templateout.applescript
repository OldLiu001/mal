use framework "Foundation"
use scripting additions

-- 创建一个新的 NSString
set myString to current application's NSString's stringWithString:"这是一个新的NSString示例。"

-- 输出 NSString
log myString
set outputString to myString

-- 创建一个 NSString
set myString to current application's NSString's stringWithString:"这是一个示例字符串。"

set myString to current application's NSString's stringWithString:"user> "

-- 将 NSString 转换为 NSData
set myData to myString's dataUsingEncoding:(current application's NSUTF8StringEncoding)

-- 输出 NSData
log myData


-- 获取标准输出的文件句柄
set stdoutHandle to current application's NSFileHandle's fileHandleWithStandardOutput
-- 写入标准输出
stdoutHandle's writeData:(myData)
log 123
