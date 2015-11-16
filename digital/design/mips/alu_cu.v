//////////////////////////////////////////////////////////////////////////
//Desription:control unit for alu   	  		                        		//
//////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ps

module alu_cu(i_function, i_opcode, o_alu_ctrl, o_wrong_instr);
	

	//Port declarations
	input  		  [5 : 0] 	i_function;
	input  		  [5 : 0] 	i_opcode;
	output reg 	[5 : 0] 	o_alu_ctrl;
	output reg 	          o_wrong_instr;    //here checks only func if it has correct 
                                          //and command is R-type
                                          //opcode check mips_cu

	`include "local_params.v"
	`include "commands_param.v"
	
  //------------------------------------------------------------------------
  
  //decode opcode
	always @* begin
	//	o_alu_ctrl = 'h0;   //if we have unrecognisible command it must not launch overflow interrupt
                        //overlow command ADD, SUB - they must not launch here
		//TODO:to case or not? check when will have correct int handler
		o_alu_ctrl = {i_opcode[3],2'b00, i_opcode[2:0]};
		o_wrong_instr = 1'b0;
		case(i_opcode)
			R_TYPE: begin
					o_alu_ctrl = i_function;
					//o_alu_ctrl = {func_out, i_function[1 : 0]};
          //we can have two types of wrong instruction:
          //--opcode    - checks in mips_cu
          //--function
          //so here wrong instruction depends wrong function 
					o_wrong_instr = i_function != 6'hc &
													i_function != 6'hd &
													i_function != 6'h2a &
													i_function != 6'h2b &
													!((i_function >= 6'h18) & (i_function <= 6'h1b)) &
													!(i_function <= 6'h13) &
													!((i_function >= 6'h20) & (i_function <= 6'h27));
					//o_wrong_instr = wrong_instr_func;
				end
			SLTI, SLTIU: 														o_alu_ctrl = {SLT_OUT, i_opcode[1 : 0]};
			LUI: 		  															o_alu_ctrl = {LUI_OUT, SLL};
		//	I_TYPE: 																o_alu_ctrl = i_opcode[ALU_CTRL_WIDTH - 1 : 0];
			BEQ, BNE: 															o_alu_ctrl = {ADDER_OUT, SUBU};
			SB, SH, SW, LB, LH, LW, LBU, LHU, 
			LWR, LWL, SWR, SWL,
			JAL, BRANCHES, BGTZ, BLEZ:							o_alu_ctrl = {ADDER_OUT, ADDU};
		endcase
	end

endmodule 
