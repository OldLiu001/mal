module testbench;
reg [7:0] data;
integer file;
integer status;

initial begin
// 打开标准输入
//file = $fopen("top_module.v", "r");
file = $fopen("/proc/self/fd/0", "r");

if (|file) begin
while (!$feof(file)) begin
// 从标准输入读取数据
//status = $fscanf(0, "%s\n", data);
status = $fscanf(0, "%c", data);
if (status == 1) begin
$display("Read data: %d", data);//10=newline
end else begin
$display("Error reading data"); //file eof
end
end
$fclose(file);
end else begin
$display("Failed to open standard input");
end
end
endmodule
