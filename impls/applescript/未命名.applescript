use framework "Foundation"
use scripting additions
log "请输入一些文本："
current application's NSLog("Hello, World!")
current application's NSLog("Hello, World!")
current application's NSLog("Hello, World!")
current application's NSLog("Hello, World!")
current application's NSLog("Hello, World!")
current application's NSLog("Hello, World!")
current application's NSLog("Hello, World!")

-- 提示用户输入
log "请输入一些文本："
-- 创建一个 NSFileHandle 对象来读取标准输入
set inputHandle to current application's NSFileHandle's fileHandleWithStandardInput
-- 读取输入数据
set inputData to inputHandle's availableData

-- 将数据转换为字符串
set inputString to (current application's NSString's alloc's initWithData:inputData encoding:(current application's NSUTF8StringEncoding))

-- 去除字符串末尾的换行符
set trimmedString to inputString's stringByTrimmingCharactersInSet:(current application's NSCharacterSet's newlineCharacterSet)

-- 输出输入的字符串
log trimmedString as text