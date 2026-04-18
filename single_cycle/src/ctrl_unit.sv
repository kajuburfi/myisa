module ctrl_unit(
    input logic [3:0] op,
    output logic is_imm, is_rwe, is_mwe, is_memout, is_rd, is_halt,
    output logic [2:0] ctrl_alu,
    output logic [1:0] ctrl_b
  );
  logic [10:0] ctrls;
  assign {is_imm, is_rwe, is_mwe, is_memout, is_rd, is_halt, ctrl_alu, ctrl_b} = ctrls;
  always_comb begin
    case (op)
      4'b0000: ctrls = 11'b110100_000_00; //lw
      4'b0001: ctrls = 11'b101010_000_00; //sw
      4'b0010: ctrls = 11'b010000_010_00; //nand
      4'b0011: ctrls = 11'b110000_010_00; //nandi
      4'b0100: ctrls = 11'b010000_000_00; //add
      4'b0101: ctrls = 11'b110000_000_00; //addi
      4'b0110: ctrls = 11'b010000_001_00; //sub
      // 4'b0111: ctrls = 10'b // mul
      // 4'b0111: ctrls = 10'b // div
      4'b1001: ctrls = 11'b010000_011_00; //cmp
      4'b1010: ctrls = 11'b000010_000_11; //b
      4'b1011: ctrls = 11'b000010_000_01; //beq
      4'b1100: ctrls = 11'b000010_000_10; //bgt
      4'b1111: ctrls = 11'b000001_000_00;
    endcase
  end
endmodule
