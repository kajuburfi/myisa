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
