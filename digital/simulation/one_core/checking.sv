`timescale 1ns/1ps

module checking(i_clk, i_arst_n, i);
  input i_clk, i_arst_n;
  input integer i;

 wire [5 : 0] opcode; 
 wire [4:0] copr_code, raddr_w;
 wire [31 : 0] r_din, instr, data_a, data_b;
 wire [4 :0] alu_ctrl;

 `include "local_params.v"
 `include "commands_param.v"

 assign r_type = u_core.instruction[31:25] == 6'b000000;
 assign reg_en_de = u_core.rw_en_de;
 assign reg_en_ex = u_core.rw_en_ex;
 assign reg_en_ma = u_core.rw_en_ma;
 assign stall = u_core.stall_en;
 assign opcode = u_core.u_decode.opcode;
 assign test4 = i == 4;
 assign jmp = opcode == JMP;
 assign lui = opcode == LUI;
 assign branch = opcode == BNE;
 assign jr = (opcode == R_TYPE) & u_core.instruction[5:0] == JR;

 assign int_catch = u_core.u_coprocessor.o_int_only;
 assign jmp_en = u_core.u_fetch.i_jmp_en;
 assign pc_fe_eq1 = u_core.u_fetch.o_pc_fe == 2;

 assign data_a = u_core.u_execute.u_alu.i_data_a;
 assign data_b = u_core.u_execute.u_alu.i_data_b;
 assign alu_ctrl = u_core.u_execute.u_alu.i_operation;

 sequence r_type_seq;
  r_type ##1 reg_en_de ##1 reg_en_ma ##1 reg_en_ma;
 endsequence

 property r_type_prop;
  @(posedge i_clk)
    disable iff (stall | i_arst_n)
    r_type |=> r_type_seq;
 endproperty

 assert property (r_type_prop);

 sequence test4_seq;
  (lui [= 2]) ##1 (branch [= 4]) ##1 jr;
 endsequence

 property test4_prop;
  @(posedge i_clk)
    disable iff (!test4)
    jmp |=> test4_seq;
 endproperty

 assert property (test4_prop);

sequence int_reaction;
 int_catch ##0 jmp_en ##1 pc_fe_eq1;
endsequence

 property int_reaction_prop;
  @(posedge i_clk)
  disable iff (!i_arst_n)
    int_catch |-> int_reaction;
 endproperty

 assert property (int_reaction_prop);



 covergroup alu_data @(posedge i_clk);
  port_a: coverpoint data_a {
    bins positive = {0, 'h7ffffff};
    bins negative = {'h80000000, 'hffffffff};
  }
  port_b: coverpoint data_b {
    bins positive = {0, 'h7ffffff};
    bins negative = {'h80000000, 'hffffffff};
  }
  alu_ctrl: coverpoint alu_ctrl {
    bins shift = {SHIFT_OUT, SHIFT_CONSTANT_OUT, LUI_OUT};
    bins summator = {ADDER_OUT};
    bins logik = {LOGIK_OUT};
    bins slt = {SLT_OUT};
  }
 endgroup

 alu_data alu = new();

endmodule
