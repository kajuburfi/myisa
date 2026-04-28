module tb_cache;
  logic clk;

  logic is_w;
  logic [15:0] a, w, d;

  cacheController dut(clk, is_w, a, w, d);

  initial begin
    is_w = 0;
    a = 0;
    w = 0;
    #10;
    // read mem location 0x500
    a = 16'h500;
    #30;
    $display("Memory at location ox500: %04X", d);
    a = 16'h4f20;
    #30;
    $display("Memory at location ox4f20: %04X", d);
    a = 16'h30ab;
    #30;
    $display("Memory at location ox30ab: %04X", d);
    
  end

  initial begin
    #200;
    $finish;
  end

  initial begin
    clk <= 0;
    #10;
    $dumpfile("cache_dump.vcd");
    $dumpvars(0, tb_cache);
  end

  always begin
    #5; clk = ~clk;
  end
endmodule
