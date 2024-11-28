use framework "Foundation"
use scripting additions

-- 创建一个 NSString
set myString to current application's NSString's stringWithString:"这是一个示例字符串。"

-- 将 NSString 转换为 NSData
set myData to myString's dataUsingEncoding:(current application's NSUTF8StringEncoding)

-- 输出 NSData
log myData

