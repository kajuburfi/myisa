module ctrl_unit(
    input logic [3:0] op,
    output logic is_imm, is_rwe, is_mwe, is_memout, is_rd,
    output logic [2:0] ctrl_alu,
    output logic [1:0] ctrl_b
  );
  logic [9:0] ctrls;
  assign {is_imm, is_rwe, is_mwe, is_memout, is_rd, ctrl_alu, ctrl_b} = ctrls;
  always_comb begin
    case (op)
      4'b0000: ctrls = 10'b1101000000; //lw
      4'b0001: ctrls = 10'b1010000000; //sw
      4'b0010: ctrls = 10'b0100001000; //nand
      4'b0011: ctrls = 10'b1100001000; //nandi
      4'b0100: ctrls = 10'b0100000000; //add
      4'b0101: ctrls = 10'b1100000000; //addi
      4'b0110: ctrls = 10'b0100000100; //sub
      // 4'b0111: ctrls = 10'b // mul
      // 4'b0111: ctrls = 10'b // div
      4'b1001: ctrls = 10'b0100001100; //cmp
      4'b1010: ctrls = 10'b0000100011; //b
      4'b1011: ctrls = 10'b0000100001; //beq
      4'b1100: ctrls = 10'b0000100010; //bgt
    endcase
  end
endmodule
