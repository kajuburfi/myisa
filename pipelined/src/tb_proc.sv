module testbench();
  logic clk, rst;
  logic [2:0] ctrl_syscall;

  top dut (clk, rst, ctrl_syscall);

  // initial begin
  //   #500;
  //   $finish;
  // end

  initial begin
    clk <= 0;
    rst <= 1; #15; rst <= 0;
    $dumpfile("dump.vcd");
    $dumpvars(0, testbench);
  end

  always begin
    #5; clk = ~clk;
    if (ctrl_syscall == 3'b111)
      $finish;
  end
endmodule
