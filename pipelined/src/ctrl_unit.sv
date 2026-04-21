module ctrl_unit(
    input logic [15:0] instr,
    output logic is_imm, is_rwe, is_mwe, is_memout, is_rd, is_pc_reg,
    output logic [2:0] ctrl_syscall,
    output logic [2:0] ctrl_alu,
    output logic [1:0] ctrl_b
  );
  logic [10:0] ctrls;
  logic [3:0] op;
  assign op = instr[15:12];
  assign is_pc_reg = (instr[7] & instr[5]) & (~(instr[4] | instr[6]));
  assign {is_imm, is_rwe, is_mwe, is_memout, is_rd, ctrl_alu, ctrl_b} = ctrls;
  // initial begin
  //   ctrls = 13'b00000_000_000_00;
  // end
  always_comb begin
    if (instr == 16'hFFFF) begin
      ctrl_syscall = 3'b111;
      ctrls = 10'b00000_000_00;
    end

    case (op) 
      default: ctrls = 10'b00000_000_00;
      4'b0000: ctrls = 10'b11010_000_00; //lw
      4'b0001: ctrls = 10'b10101_000_00; //sw
      4'b0010: ctrls = 10'b01000_010_00; //nand
      4'b0011: ctrls = 10'b11000_010_00; //nandi
      4'b0100: ctrls = 10'b01000_000_00; //add
      4'b0101: ctrls = 10'b11000_000_00; //addi
      4'b0110: ctrls = 10'b01000_001_00; //sub
      // 4'b0111: ctrls = 10'b // mul
      // 4'b0111: ctrls = 10'b // div
      4'b1001: ctrls = 10'b01000_011_00; //cmp
      4'b1010: ctrls = 10'b00001_000_11; //b
      4'b1011: ctrls = 10'b00001_000_01; //beq
      4'b1100: ctrls = 10'b00001_000_10; //bgt
    endcase
  end
endmodule
