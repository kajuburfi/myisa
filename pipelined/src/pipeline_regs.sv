module fd_pr(
  input logic clk,
  input logic is_imm_old, is_rd_old, is_rwe_old, is_pc_reg_old, is_mwe_old, is_memout_old,
  input logic [2:0] ctrl_alu_old, ctrl_syscall_old,
  input logic [1:0] ctrl_b_old,
  input logic [15:0] pc_old, instr_old, imm_old,
  output logic is_imm, is_rd, is_rwe, is_pc_reg, is_mwe, is_memout,
  output logic [2:0] ctrl_alu, ctrl_syscall,
  output logic [1:0] ctrl_b,
  output logic [15:0] pc, instr, imm
);
  always_ff @(posedge clk) begin
    is_imm <= is_imm_old;
    is_rd <= is_rd_old;
    is_rwe <= is_rwe_old;
    is_pc_reg <= is_pc_reg_old;
    is_mwe <= is_mwe_old;
    is_memout <= is_memout_old;
    ctrl_syscall <= ctrl_syscall_old;
    ctrl_alu <= ctrl_alu_old;
    ctrl_b <= ctrl_b_old;
    pc <= pc_old;
    instr <= instr_old;
    imm <= imm_old;
  end
endmodule

module de_pr(
  input logic clk,
  input logic is_imm_old, is_rwe_old, is_pc_reg_old, is_mwe_old, is_memout_old,
  input logic [2:0] ctrl_alu_old, ctrl_syscall_old,
  input logic [15:0] pc_old, rr2_old, rr1_old, imm_old, instr_old,
  output logic is_imm, is_rwe, is_pc_reg, is_mwe, is_memout,
  output logic [2:0] ctrl_alu, ctrl_syscall,
  output logic [15:0] pc, rr2, rr1, imm, instr
);
  always_ff @(posedge clk) begin
    is_imm <= is_imm_old;
    is_rwe <= is_rwe_old;
    is_pc_reg <= is_pc_reg_old;
    is_mwe <= is_mwe_old;
    is_memout <= is_memout_old;
    ctrl_syscall <= ctrl_syscall_old;
    ctrl_alu <= ctrl_alu_old;
    pc <= pc_old;
    rr2 <= rr2_old;
    rr1 <= rr1_old;
    imm <= imm_old;
    instr <= instr_old;
  end
endmodule

module em_pr(
  input logic clk,
  input logic is_rwe_old, is_mwe_old, is_memout_old,
  input logic [2:0] ctrl_syscall_old,
  input logic [15:0] aluout_old, rr1_old, instr_old,
  output logic is_rwe, is_mwe, is_memout,
  output logic [2:0] ctrl_syscall,
  output logic [15:0] aluout, rr1, instr
);
  always_ff @(posedge clk) begin
    is_rwe <= is_rwe_old;
    is_mwe <= is_mwe_old;
    is_memout <= is_memout_old;
    ctrl_syscall <= ctrl_syscall_old;
    aluout <= aluout_old;
    rr1 <= rr1_old;
    instr <= instr_old;
  end
endmodule

module mw_pr(
  input logic clk,
  input logic is_rwe_old, is_memout_old,
  input logic [2:0] ctrl_syscall_old,
  input logic [15:0] aluout_old, rm_old, instr_old,
  output logic is_rwe, is_memout,
  output logic [2:0] ctrl_syscall,
  output logic [15:0] aluout, rm, instr
);
  always_ff @(posedge clk) begin
    is_rwe <= is_rwe_old;
    is_memout <= is_memout_old;
    ctrl_syscall <= ctrl_syscall_old;
    aluout <= aluout_old;
    rm <= rm_old;
    instr <= instr_old;
  end
endmodule
