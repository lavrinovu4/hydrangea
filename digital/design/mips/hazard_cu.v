//////////////////////////////////////////////////////////////////
//Description: stall enable for freezing mips if we have hazard //
//////////////////////////////////////////////////////////////////

`timescale 1ns/1ps

module hazard_cu(i_opcode, i_branch_en, i_rs, i_rt, 
									i_ws_ex, i_ws_ma, i_ws_wb, i_wen_ex, i_wen_ma, i_wen_wb,
									o_stall_en);

	parameter OPCODE_WIDTH = 6;
	parameter ADDR_REG = 5;

	//Port declarations
	input [OPCODE_WIDTH - 1 : 0] 	i_opcode;
  input                         i_branch_en;    //if catch branch, need stall per one clock
	input [ADDR_REG - 1 : 0] 	  	i_rs;
	input [ADDR_REG - 1 : 0] 	  	i_rt;
	input [ADDR_REG - 1 : 0] 	  	i_ws_ex; 				//write sourse to register
	input [ADDR_REG - 1 : 0] 	  	i_ws_ma;
	input [ADDR_REG - 1 : 0] 	  	i_ws_wb;
	input 												i_wen_ex;
	input 												i_wen_ma;
	input 												i_wen_wb;
	output 							          o_stall_en;

	//-----------------------------------------Internal variables--------------------------------------------
	wire re1;
	wire re2;
	wire we_ex;
	wire we_ma;
	wire we_wb;

	`include "commands_param.v"
	//-----------------------------------------Variable assigments-------------------------------------------
	assign re1 = !(i_opcode == JMP) | !(i_opcode == COPR0) | !(i_opcode == JAL);
	assign re2 = (i_opcode == R_TYPE) |
							 (i_opcode == SW) | (i_opcode == SH) | (i_opcode == SB) | (i_opcode == SWR) | (i_opcode == SWL) |
				 			 (i_opcode == COPR0) | (i_opcode == BNE) | (i_opcode == BEQ) | (i_opcode == LWL) | (i_opcode == LWR);

	assign we_ex = i_ws_ex != 0 & i_wen_ex;
	assign we_ma = i_ws_ma != 0 & i_wen_ma;
	assign we_wb = i_ws_wb != 0 & i_wen_wb;

	assign o_stall_en = (	(i_rs == i_ws_ex) & we_ex |
							(i_rs == i_ws_ma) & we_ma |
							(i_rs == i_ws_wb) & we_wb	) & re1 |
						( 	(i_rt == i_ws_ex) & we_ex |
							(i_rt == i_ws_ma) & we_ma |
							(i_rt == i_ws_wb) & we_wb	) & re2 |
              i_branch_en;

endmodule
