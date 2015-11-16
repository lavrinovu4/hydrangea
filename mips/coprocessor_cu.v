//////////////////////////////////////////////////////////////////////////////////////
//description: control unit for coprocessor                                         //
//////////////////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ps

module coprocessor_cu(i_opcode, i_copr_code, o_eret, o_copr_we, o_copr_re, o_copr_wr_instr);

  parameter OPCODE_WIDTH = 6;
  parameter COPR_CODE_WIDTH = 5;

  //Port declaration
  input [OPCODE_WIDTH - 1 : 0] i_opcode;
  input [COPR_CODE_WIDTH - 1 : 0] i_copr_code;
  output reg o_eret;
  output reg o_copr_we;
  output reg o_copr_re;
  output reg o_copr_wr_instr;

  //-----------------------------------Internal variables-------------------------------
  `include "local_params.v"

  //-----------------------------------Code start---------------------------------------
  always @* begin
    o_eret = 1'b0;
    o_copr_we = 1'b0;
    o_copr_re = 1'b0;
    o_copr_wr_instr = 1'b0;
    if(i_opcode == COPR) begin
      case(i_copr_code)
        MFC0:o_copr_re = 1'b1;
        MTC0:o_copr_we = 1'b1;
        RFE: o_eret = 1'b1;
        default: o_copr_wr_instr = 1'b1;
      endcase
    end
  end

endmodule
