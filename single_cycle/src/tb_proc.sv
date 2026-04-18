module testbench();
  logic clk, rst, is_halt;

  top dut (clk, rst, is_halt);

  // initial begin
  //   #500;
  //   $finish;
  // end

  initial begin
    clk <= 0;
    rst <= 1; #5; rst <= 0;
    $dumpfile("dump.vcd");
    $dumpvars(0, testbench);
  end

  always begin
    #5; clk = ~clk;
    if (is_halt == 1)
      $finish;
  end
endmodule
