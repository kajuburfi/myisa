/*


// All hardcoded... sorry!

// Control cache hits and misses and write backs and all
module cacheController(
  input logic clk, is_w,
  input logic [15:0] a1, w1,
  output logic [15:0] d1
);
  logic [15:0] dirty_data, dirty_addr;
  logic is_dirty, hit1;

  logic [15:0] addr1, wd1, dd1;
  logic [15:0] addr1M, wd1M, dd1M;
  logic is_wM, enM;

  assign addr1 = a1;
  assign wd1 = w1;

  initial begin
    enM = 0;
    is_wM = 0;
  end

  L1cache l1_inst(clk, is_w, addr1, wd1, dd1, dirty_data, dirty_addr, hit1, is_dirty);
  mainMemory mem_inst(clk, is_wM, enM, addr1M, wd1M, dd1M);
  // mainMemory mem_inst(clk, is_w, enM, addr1, wd1, dd1);
  // always_ff @(posedge clk)
  //   d1 <= dd1;

  always_ff @(posedge clk) begin
    if (hit1) begin
      d1 <= dd1;
    end else if (~hit1) begin
      enM <= 1;
      addr1M <= addr1;
      wd1M <= wd1;
      d1 <= dd1M;
    end

    if (is_dirty) begin
      enM <= 1;
      addr1M <= dirty_addr;
      wd1M <= dirty_data;
    end
  end
endmodule

// L1 Cache - 1 cycle fetch time
// Write Back
// Random replacement - try for pseudo LRU later
// 8 way associative
module L1cache(
  input logic clk, is_w,
  input logic [15:0] a1, w1,
  output logic [15:0] d1,
  output logic [15:0] dirty_data, dirty_addr,
  output logic hit1, is_dirty
);
  // 31 bit wide vector, with 8 sets and 8 way associative
  // V | D | tag | data
  // 1 | 1 | 13  |  16   [bits]
  logic [30:0] l1 [7:0][7:0];
  //    cache      way  set
  //    packed     unpacked    [verilog stuff]

  logic [2:0] idx;
  logic [12:0] tag;
  assign idx = a1[2:0];
  assign tag = a1[15:3];

  logic [7:0] wayout;
  logic [7:0] validout;
  logic [15:0] dataout [7:0];
  logic [12:0] tagout [7:0];

  logic [2:0] s;
  logic are_all_valid;

  generate
    genvar i;
    for (i=0;i<8;i++) begin
      assign validout[i] = l1[i][idx][30];
      assign wayout[i] = validout[i] & (&(~(tag ^ l1[i][idx][28:16])));
      assign dataout[i] = l1[i][idx][15:0];
    end
  endgenerate

  assign are_all_valid = &validout;
  // assign hit1 = |wayout;
  always_comb begin
    if (|wayout == 1)
      hit1 = 1;
    else
      hit1 = 0;
  end

  encoder_8_3 encoder(wayout, s);
  assign d1 = dataout[s];

  logic [30:0] new_data;
  assign new_data = {1'b1, 1'b1, tag, w1};
  logic [30:0] writeback_data;
  mux #(1) mux_dirty(1'b0, l1[0][idx][29], is_w, is_dirty);
  mux #(31) mux_wb_data(l1[0][idx], new_data, is_w, writeback_data);

  assign dirty_data = l1[0][idx][15:0];
  assign dirty_addr = {l1[0][idx][28:16], idx};

  always_ff @(negedge clk) begin
    if (is_w)
      l1[0][idx] = writeback_data;
  end


endmodule

// L2 Cache - 3 cycle latency
// Write through
// Pseudo LRU
// 4 way associative
module L2cache();
endmodule

*/

/* This takes waay too much time to compile, perhaps because of the insanely
   large array that it must remember dynamically

module mainMemory(
  input logic clk, is_w, en,
  input logic [15:0] a, w,
  output logic [15:0] d
);
  logic [15:0] mem [0:65535];
  initial begin
    $readmemh("mem.hex", mem);
  end

  always_ff @(posedge clk) begin
    if (is_w && en) begin
      mem[a] <= w;
      $display("Wrote memory");
    end
  end

  always_ff @(posedge clk) begin
    if (~is_w && en) begin
      d <= mem[a];
      $display("Read memory");
    end
  end
endmodule
*/


module mainMemory (
  input  wire        clk,
  input  wire        we,
  input  wire [15:0] addr,
  input  wire [15:0] din,
  output reg [15:0]  dout
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
      $display("ERROR: %s not found or cannot open. Ensure file exists and has 65536 lines of 4 hex digits.", FNAME);
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
    reg [3:0] n0, n1, n2, n3;
    begin
      file_read_hex_word = 16'h0000;
      okseek = seek_line(a);
      if (okseek != 0) begin
        $display("fseek read error at addr %0d", a);
      end else begin
        c0 = $fgetc(fh); c1 = $fgetc(fh); c2 = $fgetc(fh); c3 = $fgetc(fh); nl = $fgetc(fh);
        if (c0 === -1 || c1 === -1 || c2 === -1 || c3 === -1) begin
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
    reg [7:0] c0, c1, c2, c3;
    begin
      okseek = seek_line(a);
      if (okseek != 0) begin
        $display("fseek write error at addr %0d", a);
      end else begin
        c0 = nibble_to_ascii(v[15:12]);
        c1 = nibble_to_ascii(v[11:8]);
        c2 = nibble_to_ascii(v[7:4]);
        c3 = nibble_to_ascii(v[3:0]);
        // overwrite 4 chars + newline (keep newline as '\n')
        $fputc(c0, fh); $fputc(c1, fh); $fputc(c2, fh); $fputc(c3, fh); $fputc(8'h0A, fh);
        $fflush(fh);
      end
    end
  endtask

  // Synchronous: write then read 
  always @(posedge clk) begin
    if (we) file_write_hex_word(addr, din);
  end
  assign dout = file_read_hex_word(addr);

  final begin
    if (fh != 0) $fclose(fh);
  end
endmodule


// WORKS!!!!!!
// // small sanity testbench (assumes mem.hex exists)
// module tb;
//   reg clk = 0; always #5 clk = ~clk;
//   reg we; reg [15:0] addr; reg [15:0] din; wire [15:0] dout;
//   mainMemory uut(.clk(clk), .we(we), .addr(addr), .din(din), .dout(dout));

//   initial begin
//     // write to addr 1, read back
//     we = 1; addr = 16'd5000; din = 16'hABCD; #10;
//     we = 0; addr = 16'd5000; #10;
//     $display("Read addr 1 = %04h", dout);

//     // write to last addr, read back
//     we = 1; addr = 16'd65535; din = 16'h55AA; #10;
//     we = 0; addr = 16'd65535; #10;
//     $display("Read addr 65535 = %04h", dout);

//     $finish;
//   end
// endmodule

