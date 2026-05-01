// All hardcoded... sorry!

module MemoryController(
  input logic clk, mwe,
  input logic req1, req2, req3,
  input logic [15:0] waddr, wdata,
  input logic [15:0] a1, a2,
  output logic [15:0]  d1, d2, d3
);  
  // Handles inputs to L1 Cache
  logic L1req1, L1req2, L1req3;
  logic [15:0] L1waddr, L1wdata;
  logic [15:0] L1a1, L1a2;
  logic [15:0] L1d1, L1d2, L1d3;

  // Handles input to mainmem
  logic Mreq1, Mreq2, Mreq3;
  logic [15:0] Mwaddr, Mwdata;
  logic [15:0] Ma1, Ma2;
  logic [15:0] Md1, Md2, Md3;

  // Other internal wires required for L1 cache
  logic h1, h2, h3, is_dirty, C_w, M_w, is_mem;
  logic [15:0] wb_addr, wb_data;

  // On a cache miss, we need to read from main memory.
  // When we do so, we need to write what we read from the main memory
  // to the cache.
  // Since we can read upto 3 addr at a time, but only can write one at a time,
  // we need to order the writes into cache.
  // This is sort of a buffer for the same.
  logic [31:0] l1C_write [2:0];
  // Unpacked - [a3, a2, a1] 
  // Packed - {waddr, wdata} -> [31:16] and [15:0]
  logic need_l1C_write [2:0]; // To remember what all to write
  logic pause_mem_op; // Sort of like stalling these operations

  initial begin
    C_w = mwe;
    M_w = 0;
    pause_mem_op = 0;
  end

  L1Cache l1_inst(
    clk, C_w, is_mem,
    L1req1, L1req2, L1req3,
    L1waddr, L1wdata,
    L1a1, L1a2,
    L1d1, L1d2, L1d3,
    h1, h2, h3, is_dirty,
    wb_addr, wb_data
  );

  mainMemory main_inst(
    clk, M_w,
    Mreq1, Mreq2, Mreq3,
    Mwaddr, Mwdata,
    Ma1, Ma2,
    Md1, Md2, Md3
  );

  always_ff @(negedge clk) begin
    if (~pause_mem_op) begin
      // Send to L1Cache
      L1req1 <= req1;
      L1req2 <= req2;
      L1req3 <= req3;
      L1waddr <= waddr;
      L1wdata <= wdata;
      L1a1 <= a1;
      L1a2 <= a2;

      // If cache miss for a1; send to main memory
      if (~h1) begin
        // $display("[%0t] MISS h1", $time); // DEBUG_HIGH
        Mreq1 <= req1;
        Ma1 <= a1;
      end else if (h1) begin
        // $display("[%0t] HIT  h1", $time); // DEBUG_HIGH
        d1 <= L1d1;
        Mreq1 <= 0;
      end
      // Take response of main mem
      if (Mreq1) begin
        // $display("[%0t] Mreq1 == 1", $time); // DEBUG_HIGH

        // Write to the buffer first
        l1C_write[0] <= {Ma1, Md1};
        need_l1C_write[0] <= 1;
        // L1waddr <= Ma1;
        // L1wdata <= Md1;
        // C_w <= 1;
        // is_mem <= 1;
      end else if (~Mreq1) begin
        // $display("[%0t] Mreq1 == 0", $time); // DEBUG_HIGH
        C_w <= 0;
        is_mem <= 0;
      end

      // If cache miss for a2; send to main memory
      if (~h2) begin
        // $display("[%0t] MISS h2", $time); // DEBUG_HIGH
        Mreq2 <= req2;
        Ma2 <= a2;
      end else if (h2) begin
        // $display("[%0t] HIT  h2", $time); // DEBUG_HIGH
        d2 <= L1d2;
        Mreq2 <= 0;
      end
      // Take response of main mem
      if (Mreq2) begin
        // $display("[%0t] Mreq2 == 1", $time); // DEBUG_HIGH
        l1C_write[1] <= {Ma2, Md2};
        need_l1C_write[1] <= 1;
        // L1waddr <= Ma2;
        // L1wdata <= Md2;
        // C_w <= 1;
        // is_mem <= 1;
      end else if (~Mreq2) begin
        // $display("[%0t] Mreq2 == 0", $time); // DEBUG_HIGH
        C_w <= 0;
        is_mem <= 0;
      end

      // If cache miss for a3; send to main memory
      if (~h3) begin
        // $display("[%0t] MISS h3", $time); // DEBUG_HIGH
        Mreq3 <= req3;
        Mwaddr <= waddr;
      end else if (h3) begin
        // $display("[%0t] HIT  h3", $time); // DEBUG_HIGH
        d3 <= L1d3;
        Mreq3 <= 0;
      end
      // Take response of main mem
      if (Mreq3) begin
        // $display("[%0t] Mreq3 == 1", $time); // DEBUG_HIGH
        l1C_write[2] <= {Mwaddr, Md3};
        need_l1C_write[2] <= 1;
        // L1waddr <= Mwaddr;
        // L1wdata <= Md3;
        // C_w <= 1;
        // is_mem <= 1;
      end else if (~Mreq3) begin
        // $display("[%0t] Mreq3 == 0", $time); // DEBUG_HIGH
        C_w <= 0;
        is_mem <= 0;
      end

      // Check for dirtyness
      if (is_dirty) begin
        // $display("[%0t] Dirty", $time); // DEBUG_HIGH
        M_w <= 1;
        Mwaddr <= wb_addr;
        Mwdata <= wb_data;      
      end
    end // END PAUSE_MEM_OP

    // Writing from mem to cache
    if ( // if more than one is high
      (need_l1C_write[0] & need_l1C_write[1]) ||
      (need_l1C_write[1] & need_l1C_write[2]) ||
      (need_l1C_write[0] & need_l1C_write[2])
    ) begin
      pause_mem_op <= 1;
    end else begin
      pause_mem_op <= 0;
    end

    if (need_l1C_write[0]) begin
      L1waddr <= Ma1;
      L1wdata <= Md1;
      C_w <= 1;
      is_mem <= 1;
      need_l1C_write[0] <= 0;
    end else if (need_l1C_write[1]) begin
      L1waddr <= Ma2;
      L1wdata <= Md2;
      C_w <= 1;
      is_mem <= 1;
      need_l1C_write[1] <= 0;
    end else if (need_l1C_write[2]) begin
      L1waddr <= Mwaddr;
      L1wdata <= Md3;
      C_w <= 1;
      is_mem <= 1;
      need_l1C_write[2] <= 0;
    end

  end
  
endmodule

// Direct mapped simple cache
module L1Cache(
  input logic clk, is_w, is_mem, // is_mem => am I copying from memory value?
  input logic req1, req2, req3, // Signals to repr whether I'm requesting for a certain value
  input logic [15:0] waddr, wdata,
  input logic [15:0] a1, a2,
  output logic [15:0]  d1, d2, d3,
  // ctrl signals
  output logic h1, h2, h3, is_dirty,
  output logic [15:0] wb_addr, wb_data
);
  logic [15:0] l1data [7:0];
  logic [12:0] l1tag [7:0];
  logic [7:0] l1valid;
  logic [7:0] l1dirty;

  initial begin
    l1valid = 8'b0;
    l1dirty = 8'b0;
  end

  logic [2:0] idx1, idx2, idx3;
  logic [12:0] tag1, tag2, tag3;
  assign idx1 = a1[2:0];
  assign idx2 = a2[2:0];
  assign idx3 = waddr[2:0];
  assign tag1 = a1[15:3];
  assign tag2 = a2[15:3];
  assign tag3 = waddr[15:3];

  always_ff @(posedge clk) begin
    $display("[%0t] Cache", $time); // DEBUG_CACHE
    $display("V | D | addr | data "); // DEBUG_CACHE
    for (int i=0;i<8;i++) begin // DEBUG_CACHE
      $display("%h | %h | %04h | %04h", l1valid[i], l1dirty[i], {l1tag[i], i[2:0]}, l1data[i]); // DEBUG_CACHE
    end // DEBUG_CACHE

    if (req1) begin
      if (l1tag[idx1] == tag1 && l1valid[idx1] == 1) begin
      //   $display("[%0t] HIT 1", $time); // DEBUG_HIGH
        d1 <= l1data[idx1];
        h1 <= 1;
      end else begin
      //   $display("[%0t] MISS 1", $time); // DEBUG_HIGH
        h1 <= 0;
      end
    end

    if (req2) begin
      if (l1tag[idx2] == tag2 && l1valid[idx2] == 1) begin
      //   $display("[%0t] HIT 2", $time); // DEBUG_HIGH
        d2 <= l1data[idx2];
        h2 <= 1;
      end else begin
      //   $display("[%0t] MISS 2", $time); // DEBUG_HIGH
        h2 <= 0;
      end
    end

    if (req3) begin
      if (l1tag[idx3] == tag3 && l1valid[idx3] == 1) begin
      //   $display("[%0t] HIT 3", $time); // DEBUG_HIGH
        d3 <= l1data[idx3];
        h3 <= 1;
      end else begin
      //   $display("[%0t] MISS 3", $time); // DEBUG_HIGH
        h3 <= 0;
      end
    end
  end

  always_ff @(posedge clk) begin
    if (is_w) begin
      if (l1dirty[idx3]) begin
      //   $display("[%0t] DIRTY", $time); // DEBUG_HIGH
        wb_data <= l1data[idx3];
        wb_addr <= {l1tag[idx3], idx3};
        is_dirty <= 1;
      end

      // $display("[%0t] WRITE %04x in addr %04x", $time, wdata, {tag3, idx3}); // DEBUG_HIGH
      l1data[idx3] <= wdata;
      l1tag[idx3] <= tag3;
      l1valid[idx3] <= 1;
      if (~is_mem) begin
      //   $display("[%0t] is_mem == 0"); // DEBUG_HIGH
        l1dirty[idx3] <= 1;
      end
    end
  end

  // // Reset the ctrl signals
  // always_ff @(posedge clk) begin
  //   if (is_dirty)
  //     is_dirty <= 0;
  //   if (h1)
  //     h1 <= 0;
  //   if (h2)
  //     h2 <= 0;
  //   if (h3)
  //     h3 <= 0;
  // end
endmodule

module mainMemory (
  input logic clk, mwe,
  input logic req1, req2, req3, // Signals to repr whether I'm requesting for a certain value
  input logic [15:0] waddr, wdata,
  input logic [15:0] a1, a2,
  output logic [15:0]  d1, d2, d3
);
  // File parameters
  localparam FNAME = "mem.hex";
  localparam LINE_BYTES = 5; // 4 hex chars + '\n'
  integer fh;
  integer ok;
  integer i;

  // open existing mem.hex (must be pre-created with 65536 lines of 4 hex chars + newline)
  initial begin
    fh = $fopen(FNAME, "r+");
    if (fh == 0) begin
      $display("[%0t] ERROR: %s not found or cannot open. Ensure file exists and has 65536 lines of 4 hex digits.", FNAME, $time);
      $finish;
    end
  end

  // helper: hex nibble (0..15) -> ASCII code
  function [7:0] nibble_to_ascii(input [3:0] n);
    begin
      if (n < 10) nibble_to_ascii = 8'h30 + n; // '0'..'9'
      else nibble_to_ascii = 8'h41 + (n - 10); // 'A'..'F'
    end
  endfunction

  // helper: ASCII hex char -> nibble (0..15), returns 0 on invalid
  function [3:0] ascii_to_nibble(input [7:0] c);
    begin
      if (c >= "0" && c <= "9") ascii_to_nibble = c - "0";
      else if (c >= "A" && c <= "F") ascii_to_nibble = c - "A" + 4'd10;
      else if (c >= "a" && c <= "f") ascii_to_nibble = c - "a" + 4'd10;
      else ascii_to_nibble = 4'd0;
    end
  endfunction

  // seek to start of line for word address 'a'
  function integer seek_line(input integer a);
    integer byte_off;
    begin
      byte_off = a * LINE_BYTES;
      seek_line = $fseek(fh, byte_off, 0); // returns 0 on success in iverilog
    end
  endfunction

  // read 16-bit word from hex file at address a
  function [15:0] file_read_hex_word(input integer a);
    integer okseek;
    integer c0, c1, c2, c3, nl;
    logic [3:0] n0, n1, n2, n3;
    begin
      file_read_hex_word = 16'h0000;
      okseek = seek_line(a);
      if (okseek != 0) begin
        $display("[%0t] fseek read error at addr %0d", a, $time);
      end else begin
        c0 = $fgetc(fh); c1 = $fgetc(fh); c2 = $fgetc(fh); c3 = $fgetc(fh); nl = $fgetc(fh);
        if (c0 == -1 || c1 == -1 || c2 == -1 || c3 == -1) begin
          file_read_hex_word = 16'h0000;
        end else begin
          n0 = ascii_to_nibble(c0[7:0]);
          n1 = ascii_to_nibble(c1[7:0]);
          n2 = ascii_to_nibble(c2[7:0]);
          n3 = ascii_to_nibble(c3[7:0]);
          file_read_hex_word = {n0, n1, n2, n3}; // concatenates nibbles -> 16 bits
        end
      end
    end
  endfunction

  // write 16-bit word as 4 hex chars + newline in-place at address a
  task file_write_hex_word(input integer a, input [15:0] v);
    integer okseek;
    logic [7:0] c0, c1, c2, c3;
    integer temp0, temp1, temp2, temp3, temp4; // for the return values of fputc
    begin
      okseek = seek_line(a);
      if (okseek != 0) begin
        $display("[%0t] fseek write error at addr %0d", a, $time);
      end else begin
        c0 = nibble_to_ascii(v[15:12]);
        c1 = nibble_to_ascii(v[11:8]);
        c2 = nibble_to_ascii(v[7:4]);
        c3 = nibble_to_ascii(v[3:0]);
        // overwrite 4 chars + newline (keep newline as '\n')
        temp0 = $fputc(c0, fh);
        temp1 = $fputc(c1, fh);
        temp2 = $fputc(c2, fh);
        temp3 = $fputc(c3, fh);
        temp4 = $fputc(8'h0A, fh);
        $fflush(fh);
      end
    end
  endtask

  // Sync write
  always @(posedge clk) begin
    if (mwe) file_write_hex_word(waddr, wdata);
  end
  // Async read 
  assign d1 = file_read_hex_word(a1);
  assign d2 = file_read_hex_word(a2);
  assign d3 = file_read_hex_word(waddr); //Use this IFF ~mwe

  final begin
    if (fh != 0) $fclose(fh);
  end
endmodule


// WORKS!!!!!!
// // small sanity testbench (assumes mem.hex exists)
// // for mainMemory only
// module tb_mainMemory;
//   reg clk = 0; always #5 clk = ~clk;
//   logic mwe = 0;
//   logic [15:0] waddr, wdata, a1, a2, d1, d2;
//   mainMemory uut(clk, mwe, waddr, wdata, a1, a2, d1, d2);

//   initial begin
//     // write to addr 1, read back
//     mwe = 1; waddr = 16'd5000; wdata = 16'hABCD; #10;
//     mwe = 0; a1 = 16'd5000; #10; a2 = 16'd5001; #10;
//     $display("[%0t] Read addr 1 = %04h", d1, $time);
//     $display("[%0t] Read addr 2 = %04h", d2, $time);

//     // // write to last addr, read back
//     // mwe = 1; waddr = 16'd65535; din = 16'h55AA; #10;
//     // mwe = 0; waddr = 16'd65535; #10;
//     // $display("[%0t] Read addr 65535 = %04h", dout, $time);

//     $finish;
//   end
// endmodule

// Testbench for Memory Controller
module tb_MemoryController;
  logic clk, mwe, req1, req2, req3;
  logic [15:0] waddr, wdata, a1, a2, d1, d2, d3;

  MemoryController dut(
    clk, mwe,
    req1, req2, req3,
    waddr, wdata,
    a1, a2,
    d1, d2, d3
  );

  initial begin
    clk = 0;
    $dumpfile("cache_dump.vcd");
    $dumpvars(0, tb_MemoryController);
  end
  always begin
    #5; clk = ~clk;
  end

  initial begin
    mwe = 0; req1 = 1; req2 = 1; req3 = 1;
    a1 = 16'h0000; a2 = 16'h0001; waddr = 16'h0002; #100;
    $display("[%0t] Memory at addr %04X = %04X", $time, a1, d1);
    $display("[%0t] Memory at addr %04X = %04X", $time, a2, d2);
    $display("[%0t] Memory at addr %04X = %04X", $time, waddr, d3);

    mwe = 0; req1 = 1; req2 = 1; req3 = 0;
    a1 = 16'h0003; a2 = 16'h0004; #100;
    $display("[%0t] Memory at addr %04X = %04X", $time, a1, d1);
    $display("[%0t] Memory at addr %04X = %04X", $time, a2, d2);

    mwe = 0; req1 = 1; req2 = 1; req3 = 0;
    a1 = 16'h0005; a2 = 16'h0008; #100;
    $display("[%0t] Memory at addr %04X = %04X", $time, a1, d1);
    $display("[%0t] Memory at addr %04X = %04X", $time, a2, d2);


    $finish;
  end
endmodule
