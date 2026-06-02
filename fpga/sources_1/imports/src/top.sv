module top(
  input logic clk_board,
  input logic [15:0] sw, // Switches
  input logic btnU, btnD, btnC, btnR, btnL, CPU_RESETN,
  output logic [7:0] sseg, // segments and "dp" - decimal point
  output logic [7:0] an, // anodes for the 8 digits
  output logic [15:0] LED,
  output logic [2:0] rgb1, rgb2
);
  // A little bit of logic to make the "global" clk as 40 ns.
  // Note: clk_board = 10ns
  logic clk;
  logic [1:0] clk_cnt = 0;
  always @(posedge clk_board) begin
    clk_cnt <= clk_cnt + 1;
  end
  assign clk = clk_cnt[1];
  
  // logic clk, rst;
  logic [2:0] ctrl_syscall;

  reg [15:0] ram [4095:0];
  initial begin
    $readmemh("memory.mem", ram);
  end

  logic  mwe_proc;
  logic [15:0] waddr_proc, wdata_proc;
  logic [15:0] a1_proc, a2_proc;

  logic  mwe_io;
  logic [15:0] waddr_io, wdata_io;
  logic [15:0] a1_io, a2_io;

  logic [15:0]  d1, d2, d3;
  // // Sync write
  // always @(posedge clk) begin
  //   if (mwe) // file_write_hex_word(waddr, wdata);
  //     RAM[waddr] <= wdata;
  // end
  // // Async read 
  // assign d1 = RAM[a1];
  // assign d2 = RAM[a2];
  // assign d3 = RAM[waddr]; //Use this IFF ~mwe

  logic [2:0] temp;
  logic is_CPU_RESETN;
  proc dut (((&ctrl_syscall && is_CPU_RESETN) ? 1'b0 : clk), ~is_CPU_RESETN /* || first_time */ , ctrl_syscall,
        mwe_proc,
        waddr_proc,
        wdata_proc,
        a1_proc,
        a2_proc,
        d1,
        d2,
        d3
        );

  logic is_load = 0;
  logic [15:0] mem_sel;
  logic [15:0] mem_out; // To fetch value from RAM to display
      
  // buttons related
  reg is_btnD_, is_btnU_, is_btnC_;
  logic is_write = 0;
  always_ff @(posedge clk) begin
    if (btnC) begin
        ram[mem_sel] <= sw;
    end else if (mwe_proc) begin
        ram[waddr_proc] <= wdata_proc;
        // ram[16] <= waddr_proc;
        // ram[17] <= wdata_proc;
        is_write <= 1'b1;
    end

    if (~is_CPU_RESETN)
      is_write <= 1'b0;
  end

  always_ff @(posedge clk_board) begin
    if (btnL) begin
      is_load <= 1;
    end else begin
      is_load <= 0;
    end

    if (btnD) begin
      is_btnD_ <= 1;
    end else begin
      is_btnD_ <= 0;
    end

    if (btnU) begin
      is_btnU_ <= 1;
    end else begin
      is_btnU_ <= 0;
    end

    if (btnC) begin
      is_btnC_ <= 1;
    end else begin
      is_btnC_ <= 0;
    end
  end

  always_comb begin
    if (is_btnD_ || is_btnU_ || is_load || is_btnC_) begin
        mem_out = ram[mem_sel];
    end
    d1 = ram[a1_proc];
    d2 = ram[a2_proc];
    d3 = ram[waddr_proc];
  end
  
  // HW STUFF
  //////////////////////////
  logic [6:0] seg_pattern;
  // logic [15:0] sum_out [256];

  // Slow clock type stuff:
  logic [15:0] cnt_out = 0;
  logic [2:0] digit_sel;
  logic [3:0] curr;
  
  always @(posedge clk) begin
      cnt_out <= cnt_out + 1;
  end

  logic pwm_signal;
  pwm_generator(clk, 1'b0, 8'h02, pwm_signal);
  assign rgb1[0] = (&ctrl_syscall) ? pwm_signal : 1'b0; // Like a PWM, but simpler for less brightness
  assign rgb2[0] = (&ctrl_syscall) ? pwm_signal : 1'b0;
  assign digit_sel = cnt_out[15:13];

  logic first_time;
  always_ff @(posedge clk) begin
    if (first_time && ~is_CPU_RESETN)
      first_time <= 0;
    else 
      first_time <= 1;
  end

  // Scrolling up and down the memory 
  logic is_btnU, is_btnD, is_btnR, is_btnL;
  button u_debounceU(.clk(clk), .reset_n(1'b1), .noisy(btnU), .debounced(), .p_edge(is_btnU), .n_edge(), ._edge());
  button u_debounceD(.clk(clk), .reset_n(1'b1), .noisy(btnD), .debounced(), .p_edge(is_btnD), .n_edge(), ._edge());
  button u_debounceR(.clk(clk), .reset_n(1'b1), .noisy(btnR), .debounced(is_btnR), .p_edge(), .n_edge(), ._edge());
  button u_debounceL(.clk(clk), .reset_n(1'b1), .noisy(btnL), .debounced(is_btnL), .p_edge(), .n_edge(), ._edge());
  button u_debounceCPU(.clk(clk), .reset_n(1'b1), .noisy(CPU_RESETN), .debounced(is_CPU_RESETN), .p_edge(), .n_edge(), ._edge());

  udl_counter #(.BITS(12)) DEBOUNCED_BUTTON_COUNTER (
      .clk(clk),
      .reset_n(1'b1),
      .enable(is_btnD || is_btnU || is_load),
      .up((is_btnD) ? 1'b1 : 1'b0),
      .load(is_load),
      .D(sw),
      .Q(mem_sel)
  );

  // Displaying on the sseg
  always_comb begin
      case (digit_sel)
          3'b000: begin
              curr = (~|sw || btnR) ? mem_sel[3:0] : sw[3:0];
              an = 8'b1110_1111;
              sseg = (btnR || is_load || ~|sw) ? {1'b0, seg_pattern} : {1'b1, seg_pattern};
          end
          3'b001: begin
              curr = (~|sw || btnR) ? mem_sel[7:4] : sw[7:4];
              //an = 8'b1111_1101;
              an = 8'b1101_1111;
              sseg = (btnR || is_load || ~|sw) ? {1'b0, seg_pattern} : {1'b1, seg_pattern};
          end
          3'b010: begin
              curr = (~|sw || btnR) ? mem_sel[11:8] : sw[11:8];
              //an = 8'b1111_1011;
              an = 8'b1011_1111;
              sseg = (btnR || is_load || ~|sw) ? {1'b0, seg_pattern} : {1'b1, seg_pattern};
          end
          3'b011: begin
              curr = (~|sw || btnR) ? mem_sel[15:12] : sw[15:12];
              //an = 8'b1111_0111;
              an = 8'b0111_1111;
              sseg = (btnR || is_load || ~|sw) ? {1'b0, seg_pattern} : {1'b1, seg_pattern};
          end
          3'b100: begin
              curr = mem_out[3:0];
              an = 8'b1111_1110;
              sseg = (is_load) ? {1'b0, seg_pattern} : {1'b1, seg_pattern};
          end
          3'b101: begin
              curr = mem_out[7:4];
              //an = 8'b1111_1101;
              an = 8'b1111_1101;
              sseg = (is_load) ? {1'b0, seg_pattern} : {1'b1, seg_pattern};
          end
          3'b110: begin
              curr = mem_out[11:8];
              //an = 8'b1111_1011;
              an = 8'b1111_1011;
              sseg = (is_load) ? {1'b0, seg_pattern} : {1'b1, seg_pattern};
          end
          3'b111: begin
              curr = mem_out[15:12];
              //an = 8'b1111_0111;
              an = 8'b1111_0111;
              sseg = (is_load) ? {1'b0, seg_pattern} : {1'b1, seg_pattern};
          end
          default: begin
              curr = 4'h0;
              an = 8'b1111_1111;
          end
      endcase
  end
  
  // Convert to segment display
  hex_to_7seg u_hex_to_7seg(
      .hex(curr),
      .seg(seg_pattern)
  );
  
  // Map the pattern to the digits, keep DP off(leading 1)
  // assign sseg = (btnR) ? {1'b0, seg_pattern} : {1'b1, seg_pattern};
  
  assign LED[11:0] = sw[11:0];
  // assign LED[15] = ~is_CPU_RESETN;
  // assign LED[14] = first_time;
  // assign LED[13] = ((&ctrl_syscall && is_CPU_RESETN) ? 1'b0 : clk);
  // assign LED[12] = is_write;
  // assign LED = a1_proc;
  
  // initial begin
  //   #500;
  //   $finish;
  // end

  // initial begin
  //   clk <= 0;
  //   rst <= 1; #15; rst <= 0;
  //   $dumpfile("dump.vcd");
  //   $dumpvars(0, testbench);
  // end

  // always begin
  //   #5; clk = ~clk;
  //   if (ctrl_syscall == 3'b111)
  //     $finish;
  // end
endmodule
