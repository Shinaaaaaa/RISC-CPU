// testbench top module file
// for simulation only

`timescale 1ns/1ps
module testbench;

reg clk;
reg rst;

riscv_top #(.SIM(1)) top(
    .EXCLK(clk),
    .btnC(rst),
    .Tx(),
    .Rx(),
    .led()
);

initial begin
  clk=0;
  rst=1;
  repeat(50) #1 clk=!clk;
  rst=0; 
  forever begin
    #1 clk=!clk;
    if ($time >= 3000) begin
      $finish;
    end
  end

  $finish;
end

initial begin
  $dumpfile("test.vcd");
  $dumpvars;
end

endmodule