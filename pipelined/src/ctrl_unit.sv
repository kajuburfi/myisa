module ctrl_unit(
    input logic [15:0] instr,
    output logic is_imm, is_rwe, is_mwe, is_memout, is_rd, is_pc_reg,
    output logic [2:0] ctrl_syscall,
    output logic [2:0] ctrl_alu,
    output logic [1:0] ctrl_b
  );
  logic [12:0] ctrls;
  logic [3:0] op;
  assign op = instr[3:0];
  assign is_pc_reg = (instr[7] & instr[5]) & (~(instr[4] | instr[6]));
  assign {is_imm, is_rwe, is_mwe, is_memout, is_rd, ctrl_syscall, ctrl_alu, ctrl_b} = ctrls;
  always_comb begin
    case (op)
      4'b0000: ctrls = 13'b11010_000_000_00; //lw
      4'b0001: ctrls = 13'b10101_000_000_00; //sw
      4'b0010: ctrls = 13'b01000_000_010_00; //nand
      4'b0011: ctrls = 13'b11000_000_010_00; //nandi
      4'b0100: ctrls = 13'b01000_000_000_00; //add
      4'b0101: ctrls = 13'b11000_000_000_00; //addi
      4'b0110: ctrls = 13'b01000_000_001_00; //sub
      // 4'b0111: ctrls = 10'b // mul
      // 4'b0111: ctrls = 10'b // div
      4'b1001: ctrls = 13'b01000_000_011_00; //cmp
      4'b1010: ctrls = 13'b00001_000_000_11; //b
      4'b1011: ctrls = 13'b00001_000_000_01; //beq
      4'b1100: ctrls = 13'b00001_000_000_10; //bgt
      4'b1111: ctrls = 13'b00000_111_000_00; //halt
    endcase
  end
endmodule
