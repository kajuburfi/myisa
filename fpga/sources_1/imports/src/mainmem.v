// File: mainmem.v
module lutmem(clk, mwe, a1, a2, waddr, wdata, d1, d2, d3);
  input clk;
  input mwe;
  input [15:0] a1;
  input [15:0] a2;
  input [15:0] waddr;
  input [15:0] wdata;
  output [15:0] d1;
  output [15:0] d2;
  output [15:0] d3;
  
  wire [15:0] d1, d2, d3;

  reg [15:0] ram [255:0];
  initial begin
    $readmemh("memory.mem", ram);
  end

  always @(posedge clk) begin
    if (mwe)
      ram[waddr] <= wdata;
  end
  assign d1 = ram[a1];
  assign d2 = ram[a2];
  assign d3 = ram[waddr];
endmodule

module mainmem(clk, fast_clk, mwe, a1, a2, waddr, wdata, d1, d2, d3);
  input clk;
  input fast_clk;
  input mwe;
  input [15:0] a1;
  input [15:0] a2;
  input [15:0] waddr;
  input [15:0] wdata;
  output reg [15:0] d1;
  output reg [15:0] d2;
  output reg [15:0] d3;

  wire [15:0] d1_temp, d2_temp, d3_temp;
  wire [15:0] temp;
  reg is_imm = 1'b0;

  always @(d1_temp) begin
    if (is_imm == 0) begin
    case (d1_temp[15:12])
      default: is_imm = 1'b0;
      4'b0000: is_imm = 1'b1;
      4'b0001: is_imm = 1'b1;
      4'b0011: is_imm = 1'b1;
      4'b0101: is_imm = 1'b1;
    endcase
    end else if (is_imm == 1 && clk == 1) begin
      is_imm = 1'b0;
    end
  end

  bram u_bram(fast_clk, mwe, (is_imm) ? a2 : a1, waddr, wdata, temp, d3_temp);

  dmux u_dmux(temp, is_imm, d1_temp, d2_temp);

  always @(posedge clk) begin
    d1 <= d1_temp;
    d2 <= d2_temp;
    d3 <= d3_temp;
  end
  
endmodule

module bram(clk, mwe, a1, waddr, wdata, d1, d3);
  input clk;
  input mwe;
  input [15:0] a1;
  input [15:0] waddr;
  input [15:0] wdata;
  output [15:0] d1;
  output [15:0] d3;
  
  reg [15:0] d1, d2, d3;

  (* ram_style = "block" *) reg [15:0] ram [65535:0];
  initial begin
    $readmemh("memory.mem", ram);
  end

  always @(posedge clk) begin
    if (mwe)
      ram[waddr] <= wdata;
    d1 <= ram[a1];
    d3 <= ram[waddr];
  end
endmodule
