module testbench();
  logic clk, rst;

  top dut (clk, rst);

  initial begin
    #500;
    $finish;
  end

  initial begin
    clk <= 0;
    rst <= 1; #5; rst <= 0;
    $dumpfile("dump.vcd");
    $dumpvars(0, testbench);
  end

  always begin
    #5; clk = ~clk;
  end
endmodule
