module top(
  input logic clk, rst,
  output logic is_halt
);
  // Internal wires
  logic [15:0] pcm1, pcm2, pcnext, pcnew, pc, instr,
          imm, rr1, rr2, srcA, srcB, aluout, rm, wd;
  logic [3:0] a1_in;
  // Ctrl signals
  logic is_imm, is_rwe, is_mwe, is_rd, is_memout, is_b;
  logic [2:0] ctrl_alu;
  logic [1:0] ctrl_b;
  
  // Modules and their connections.
  sub1 sub1_1(pcm1, pcm2);
  mux mux_pc1(pcm1, pcm2, is_imm, pcnext);
  mux mux_pc2(pcnext, rr2, is_b, pcnew);
  dff #(16, 16'd255) dff_pc(clk, rst, pcnew, pc);
  sub1 sub1_2(pc, pcm1);

  imem imem_module(pc, pcm1, instr, imm);
  ctrl_unit ctrl_unit_module(instr[15:12], is_imm, is_rwe, is_mwe, is_memout, is_rd, is_halt, ctrl_alu, ctrl_b);

  mux #(4) mux_instr(instr[3:0], instr[11:8], is_rd, a1_in);

  regfile rf_module(clk, is_rwe, a1_in, instr[7:4], instr[11:8], wd, rr1, rr2);

  b_box b_box_module(rr1[1:0], ctrl_b, is_b);
  mux mux_pc_rr2(rr2, pc, (instr[7] & instr[5]) & (~(instr[4] | instr[6])), srcA);
  mux mux_imm_rr1(rr1, imm, is_imm, srcB);
  
  alu alu_module(srcA, srcB, ctrl_alu, aluout);

  dmem dmem_module(clk, is_mwe, aluout, rr1, rm);

  mux mux_aluout_rm(aluout, rm, is_memout, wd);
endmodule
