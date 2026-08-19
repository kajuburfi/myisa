//
// TODO: Plan out display of mem and fix that for this board;
// test out, and debug for the next week
// 
module top(
  input logic clk_board,
  input logic [15:0] sw, // Switches
  input logic btnU, btnD, btnC, btnR, btnL, CPU_RESETN,
  output logic [7:0] sseg, // segments and "dp" - decimal point
  output logic [3:0] an, // anodes for the 8 digits
  output logic [15:0] LED,
  output logic [2:0] rgb1, rgb2,
  // Receiver port
  input logic rd_uart,      // external push button
  // output logic rx_empty,    // LED0
  input logic rx,           // Transmitter port
  // input logic [7:0] w_data, // SW0 -> SW7
  input logic wr_uart,      // right push button // (TODO) internal signal
  // output logic tx_full,     // LED1
  output logic tx,
  // Program memory directly(from ESP UART)
  input logic pgm_mem
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

  // for UART
  wire [15:0] out_data;
  wire out_empty;

  reg [15:0] ram [4095:0];
  initial begin
    $readmemh("memory.mem", ram);
  end

  logic  mwe_proc;
  logic [15:0] waddr_proc, wdata_proc;
  logic [15:0] a1_proc, a2_proc;

  logic [15:0]  d1, d2, d3;

  // logic first_time = 1'b1;
  logic is_CPU_RESETN;
  // dff #(1, 1) first_time_dff(clk, 1'b1, 1'b0, (first_time & ~is_CPU_RESETN), first_time);
  
  // logic [2:0] temp;
  logic [15:0] instrW, immW;
  proc dut (((&ctrl_syscall && is_CPU_RESETN) ? 1'b0 : clk), ~is_CPU_RESETN, ctrl_syscall,
        mwe_proc,
        waddr_proc,
        wdata_proc,
        a1_proc,
        a2_proc,
        d1,
        d2,
        d3,
        instrW,
        immW
        );

  // This is true; I'm just gonna substitute instrW[7:0] everywhere to save on LUTs
  // logic [7:0] byte_to_be_printed;
  // assign byte_to_be_printed = instrW[7:0];

  logic is_load = 0;
  logic [15:0] mem_sel;
  logic [15:0] mem_out; // To fetch value from RAM to display
      
  // buttons related
  reg is_btnD_, is_btnU_, is_btnC_;
  // logic is_write = 0; // Used for debugging
  logic is_pgm_mem;
  always_ff @(posedge clk) begin
    if (btnC) begin
      if (~out_empty) begin
        ram[mem_sel] <= out_data;
      end else begin
        ram[mem_sel] <= sw;
      end
    end else if (mwe_proc) begin
        ram[waddr_proc] <= wdata_proc;
        // ram[16] <= waddr_proc;
        // ram[17] <= wdata_proc;
        // is_write <= 1'b1; // Used for debugging
    end else if (is_pgm_mem && ~out_empty) begin
      ram[mem_sel] <= out_data;
    end

    // if (~is_CPU_RESETN) // Used for debugging
      // is_write <= 1'b0; // Used for debugging
  end

  always_ff @(posedge clk) begin
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

  logic pgm_mem_nedge;
  always_latch begin
    // Latch is inferred for mem_out here. This is exactly what I want.
    // The display gets lagged by a clock cycle if I make it a flip flop; hence a latch it remains.
    if (is_btnD_ || is_btnU_ || is_load || is_btnC_ || ~is_CPU_RESETN || pgm_mem_nedge) begin
        mem_out = ram[mem_sel];
    end
  end

  always_comb begin
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
  logic [1:0] digit_sel;
  logic [3:0] curr;
  
  always @(posedge clk) begin
      cnt_out <= cnt_out + 1;
  end
  assign digit_sel = cnt_out[15:14];

  logic pwm_signal, pwm_signal1;
  pwm_generator pwm_generator(clk, 1'b0, 8'h02, pwm_signal);
  pwm_generator pwm_generator1(clk, 1'b0, 8'h10, pwm_signal1);
  always_comb begin
    rgb1[1] = (&ctrl_syscall) ? 1'b1 : 1'b0; 
    // rgb2[1] = (&ctrl_syscall) ? pwm_signal : 1'b0;
    rgb1[2] = (out_empty) ? 1'b0 : 1'b1;
    // rgb2[2] = (out_empty) ? 1'b0 : pwm_signal;
    rgb1[0] = (rd_uart) ? 1'b0 : 1'b1; 
    // rgb2[0] = (pgm_mem) ? 1'b0 : pwm_signal1;

    rgb2[0] = ~pgm_mem || ~CPU_RESETN; // green not working in that specific module
    rgb2[1] = ~CPU_RESETN || ~rd_uart;
    rgb2[2] = ~CPU_RESETN || ~wr_uart;
  end

  // Scrolling up and down the memory 
  logic is_btnU, is_btnD, is_btnR, is_btnL;
  button u_debounceU(.clk(clk), .reset_n(1'b1), .noisy(btnU), .debounced(), .p_edge(is_btnU), .n_edge(), ._edge());
  button u_debounceD(.clk(clk), .reset_n(1'b1), .noisy(btnD), .debounced(), .p_edge(is_btnD), .n_edge(), ._edge());
  button u_debounceR(.clk(clk), .reset_n(1'b1), .noisy(btnR), .debounced(is_btnR), .p_edge(), .n_edge(), ._edge());
  button u_debounceL(.clk(clk), .reset_n(1'b1), .noisy(btnL), .debounced(is_btnL), .p_edge(), .n_edge(), ._edge());
  button u_debounceCPU(.clk(clk), .reset_n(1'b1), .noisy(CPU_RESETN), .debounced(is_CPU_RESETN), .p_edge(), .n_edge(), ._edge());
  button read_uart(.clk(clk), .reset_n(1'b1), .noisy(~rd_uart), .debounced(), .p_edge(rd_uart_pedge), .n_edge(), ._edge());
  // Negative of the input(~rd_uart) because exterior buttons need to have PULLUP
  button write_uart(.clk(clk), .reset_n(1'b1), .noisy(~wr_uart), .debounced(), .p_edge(wr_uart_pedge), .n_edge(), ._edge());
  button u_btn_pgm_mem(.clk(clk), .reset_n(1'b1), .noisy(~pgm_mem), .debounced(is_pgm_mem), .p_edge(), .n_edge(pgm_mem_nedge), ._edge());
  
  // Counter for the memory locations
  udl_counter #(.BITS(12)) DEBOUNCED_BUTTON_COUNTER (
      .clk(clk),
      .reset_n(1'b1),
      .enable(is_btnD || is_btnU || is_load || (is_pgm_mem && ~out_empty)),
      .up((is_btnD) ? 1'b1 : 1'b0),
      .load(is_load),
      .D(sw), // We get a warning here, but that's cause we want to be able to take all 16 bit input, but the counter is only tille 0x0FFF
      .Q(mem_sel)
  );

  // =================
  // UART stuff
  // =================
  // To handle writing pgm to mem
  // always_ff @(posedge clk) begin
  //   if (is_pgm_mem) begin
  //     ram[mem_sel] <= out_data;
  //   end
  // end
  
  wire [7:0] r_data;
  reg [7:0] w_data;
  wire fifo1_rd_en, fifo2_wr_en, fifo2_rd_en;
  wire [15:0] fifo2_din;
  always_comb begin
    if (wr_uart_pedge) begin
      w_data = sw[7:0];
    end else if (ctrl_syscall == 3'b001) begin
      w_data = instrW[7:0];
    end else if (ctrl_syscall == 3'b010) begin
      reg [3:0] nibble;
      case (instrW[1:0])
          2'b11: nibble = ram[immW][15:12];
          2'b10: nibble = ram[immW][11:8];
          2'b01: nibble = ram[immW][7:4];
          2'b00: nibble = ram[immW][3:0];
      endcase
      
      // Convert nibble to ASCII
      if (nibble < 4'd10)
          w_data = 8'd48 + {4'b0000, nibble};
      else
          w_data = 8'd55 + {4'b0000, nibble};
    end else begin
      w_data = 8'h00;
    end
  end
  uart #(.DBIT(8), .SB_TICK(16)) uart_driver(
      .clk(clk),
      .reset_n(is_CPU_RESETN),
      .r_data(r_data),
      .rd_uart(fifo1_rd_en),
      .rx_empty(rx_empty),
      .rx(rx),
      .w_data(w_data),
      .wr_uart((ctrl_syscall == 3'b001) || ctrl_syscall==3'b010 || wr_uart_pedge),
      // .w_data(sw[7:0]),
      // .wr_uart(wr_uart_pedge),
      .tx_full(tx_full),
      .tx(tx),
      // .TIMER_FINAL_VALUE(11'd650) // baud rate = 9600 bps
      .TIMER_FINAL_VALUE(11'd163) // baud rate = 9600 bps
      /////////////////////////////
      // Calculate this final value based on clk and baud rate chosen:
      // FINAL_VALUE = 1/(16 * baud * time_period) - 1
  );

  
  FIFO_ByteToWord_Controller u_fifo_bytetoword_controller(
      .clk(clk),
      .rst(~is_CPU_RESETN),
      .rd_btn(rd_uart_pedge || is_pgm_mem),
  
      // FIFO1 (Xilinx IP)
      .fifo1_dout(r_data),
      .fifo1_empty(rx_empty),
      .fifo1_rd_en(fifo1_rd_en),
  
      // FIFO2 (Xilinx IP)
      .fifo2_wr_en(fifo2_wr_en),
      .fifo2_full(1'b0),
      .fifo2_din(fifo2_din),
      .fifo2_empty(out_empty),
      .fifo2_rd_en(fifo2_rd_en)
  );


  fifo_generator_1 out_FIFO(
      .clk(clk),          // input wire clk
      .srst(~is_CPU_RESETN),    // input wire srst
      .din(fifo2_din),      // input wire [15 : 0] din
      .wr_en(fifo2_wr_en),  // input wire wr_en
      .rd_en(fifo2_rd_en),    // input wire rd_en
      .dout(out_data),      // output wire [15 : 0] dout
      .full(),            // output wire full
      .empty(out_empty)    // output wire empty
  );

  
  // Displaying on the sseg
  always_comb begin
      case (digit_sel)
          2'b00: begin
              if (~out_empty && ~btnR)
                curr = out_data[3:0];
              else if (|sw && ~btnR)
                curr = sw[3:0];
              else if (btnR)
                curr = mem_sel[3:0];
              else
                curr = mem_out[3:0];
              // curr = (~|sw || btnR) ? mem_sel[3:0] : ((~out_empty) ? out_data[3:0] : sw[3:0]);
              an = 4'b1110;
              sseg = (btnR || btnU || btnD || btnL) ? {1'b0, seg_pattern} : {1'b1, seg_pattern};
          end
          2'b01: begin
              if (~out_empty && ~btnR)
                curr = out_data[7:4];
              else if (|sw && ~btnR)
                curr = sw[7:4];
              else if (btnR)
                curr = mem_sel[7:4];
              else
                curr = mem_out[7:4];
              // curr = (~|sw || btnR) ? mem_sel[7:4] : ((~out_empty) ? out_data[7:4] : sw[7:4]);
              an = 4'b1101;
              sseg = (btnR || btnU || btnD || btnL) ? {1'b0, seg_pattern} : {1'b1, seg_pattern};
          end
          2'b10: begin
              if (~out_empty && ~btnR)
                curr = out_data[11:8];
              else if (|sw && ~btnR)
                curr = sw[11:8];
              else if (btnR)
                curr = mem_sel[11:8];
              else
                curr = mem_out[11:8];
              // curr = (~|sw || btnR) ? mem_sel[11:8] : ((~out_empty) ? out_data[11:8] : sw[11:8]);
              an = 4'b1011;
              sseg = (btnR || btnU || btnD || btnL) ? {1'b0, seg_pattern} : {1'b1, seg_pattern};
          end
          2'b11: begin
              if (~out_empty && ~btnR)
                curr = out_data[15:12];
              else if (|sw && ~btnR)
                curr = sw[15:12];
              else if (btnR)
                curr = mem_sel[15:12];
              else
                curr = mem_out[15:12];
              // curr = (~|sw || btnR) ? mem_sel[15:12] : ((~out_empty) ? out_data[15:12] : sw[15:12]);
              an = 4'b0111;
              sseg = (btnR || btnU || btnD || btnL) ? {1'b0, seg_pattern} : {1'b1, seg_pattern};
          end
          // 3'b100: begin
          //     curr = mem_out[3:0];
          //     an = 8'b1111_1110;
          //     sseg = (is_load) ? {1'b0, seg_pattern} : {1'b1, seg_pattern};
          // end
          // 3'b101: begin
          //     curr = mem_out[7:4];
          //     an = 8'b1111_1101;
          //     sseg = (is_load) ? {1'b0, seg_pattern} : {1'b1, seg_pattern};
          // end
          // 3'b110: begin
          //     curr = mem_out[11:8];
          //     an = 8'b1111_1011;
          //     sseg = (is_load) ? {1'b0, seg_pattern} : {1'b1, seg_pattern};
          // end
          // 3'b111: begin
          //     curr = mem_out[15:12];
          //     an = 8'b1111_0111;
          //     sseg = (is_load) ? {1'b0, seg_pattern} : {1'b1, seg_pattern};
          // end
          default: begin
              curr = 2'h0;
              an = 4'b1111;
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
  
  // assign LED[15:0] = sw[15:0];
  assign LED[12:0] = (out_empty) ? sw[12:0] : out_data;
  // assign LED[15] = (CPU_RESETN) ? pwm_signal1 : sw[15];
  // assign LED[14] = (rd_uart) ? pwm_signal1 : sw[14];
  // assign LED[13] = (wr_uart) ? pwm_signal1 : sw[13];
  // assign LED[15] = ~is_CPU_RESETN;
  // assign LED[13] = ((&ctrl_syscall && is_CPU_RESETN) ? 1'b0 : clk);
  // assign LED[12] = is_write; // Used for debugging
  // assign LED = a1_proc;
endmodule
