//////////////////////////////////////////////////////////////////
//Description: stall enable for freezing mips if we have hazard //
//////////////////////////////////////////////////////////////////

`timescale 1ns/1ps

module hazard_cu(i_opcode, i_branch_en, i_rs, i_rt, i_ws_ex, i_ws_ma, i_ws_wb, i_eret_de, i_eret_ex, i_eret_ma, o_stall_en);

	parameter OPCODE_WIDTH = 6;
	parameter ADDR_REG = 5;

	//Port declarations
	input [OPCODE_WIDTH - 1 : 0] 	i_opcode;
  input                         i_branch_en;
	input [ADDR_REG - 1 : 0] 	  	i_rs;
	input [ADDR_REG - 1 : 0] 	  	i_rt;
	input [ADDR_REG - 1 : 0] 	  	i_ws_ex; 				//write sourse to register
	input [ADDR_REG - 1 : 0] 	  	i_ws_ma;
	input [ADDR_REG - 1 : 0] 	  	i_ws_wb;
	input 												i_eret_de; 			//need check if we have eret because in
	input 												i_eret_ex;			//situation when ret & comes new interrupt we need wait untill all commands
	input 												i_eret_ma;			//in pipeline will do their work in another situation it will sae not correct epc
	output 							          o_stall_en;

	//-----------------------------------------Internal variables--------------------------------------------
	wire re1;
	wire re2;
	wire we_ex;
	wire we_ma;
	wire we_wb;

	`include "local_params.v"
	//-----------------------------------------Variable assigments-------------------------------------------
	assign re1 = !(i_opcode == JMP) | !(i_opcode == COPR);
	assign re2 = (i_opcode == R_TYPE) | (i_opcode == SW) | (i_opcode == COPR) | (i_opcode == BNE) | (i_opcode == BEQ);

	assign we_ex = i_ws_ex != 0;    //if ws != 0 it means that i write some addres in register file
	assign we_ma = i_ws_ma != 0;    //but if ws= 0 than i dont write to register file any datas so we is equal zero too
	assign we_wb = i_ws_wb != 0;

	assign o_stall_en = ((	(i_rs == i_ws_ex) & we_ex |
							(i_rs == i_ws_ma) & we_ma |
							(i_rs == i_ws_wb) & we_wb	) & re1 |
						( 	(i_rt == i_ws_ex) & we_ex |
							(i_rt == i_ws_ma) & we_ma |
							(i_rt == i_ws_wb) & we_wb	) & re2 |
              i_branch_en ) | i_eret_de | i_eret_ex | i_eret_ma;

endmodule
