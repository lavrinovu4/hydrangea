//////////////////////////////////////////////////////////////////////////
//Desription:control unit for alu   	  		                        		//
//////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ps

module alu_cu(i_function, i_opcode, o_alu_ctrl, o_wrong_instr);
	
	parameter OPCODE_WIDTH 		= 6;
	parameter FUNCTION_WIDTH 	= 6;
	parameter ALU_CTRL_WIDTH 	= 5;

	//Port declarations
	input  		  [FUNCTION_WIDTH - 1 : 0] 	i_function;
	input  		  [OPCODE_WIDTH - 1 : 0] 		i_opcode;
	output reg 	[ALU_CTRL_WIDTH - 1 : 0] 	o_alu_ctrl;
	output reg 	                  				o_wrong_instr;    //here checks only func if it has correct 
                                                          //and command is R-type
                                                          //opcode check mips_cu

	//----------------------Internal variables--------------------------
	reg [ALU_CTRL_WIDTH - 3 : 0]     func_out;             //code for alu_ctrl when decode i_function
	reg             wrong_instr_func;

	`include "local_params.v"
	
  //----------------------Code start----------------------------------
  
  //decode opcode
	always @* begin
		o_alu_ctrl = 'h0;   //if we have unrecognisible command it must not launch overflow interrupt
                        //for launch overlow command ADD, SUB - they must not launch here
		//o_wrong_instr = 0 if one of case contidion is true, else 1
		o_wrong_instr = 1'b0;
		casez(i_opcode)         //order is importamt
			R_TYPE: begin
					o_alu_ctrl = {func_out, i_function[1 : 0]};
          //we can have two types of wrong instruction:
          //--opcode    - checks in mips_cu
          //--function
          //so here wrong instruction depends wrong function 
					o_wrong_instr = wrong_instr_func;
				end
			SLTI: 		o_alu_ctrl = {SLT_OUT, i_opcode[1 : 0]};
			LUI: 		  o_alu_ctrl = {LUI_OUT, SLL};
			I_TYPE: 	o_alu_ctrl = i_opcode[ALU_CTRL_WIDTH - 1 : 0];
			BEQ: 		  o_alu_ctrl = {ADDER_OUT, SUBU};
			BNE: 		  o_alu_ctrl = {ADDER_OUT, SUBU};
			SW: 		  o_alu_ctrl = {ADDER_OUT, ADDU};
			LW: 		  o_alu_ctrl = {ADDER_OUT, ADDU};
		endcase
	end

  //decode function
	always @* begin
		func_out = 'hx;
		wrong_instr_func = 1'b0;
		casez(i_function)
      //two LSB is the same as in my alu, so for more optimise this two wire directly to alu control
			6'b00_00??: func_out = SHIFT_CONSTANT_OUT;
			6'b00_01??: func_out = SHIFT_OUT;
			6'b10_00??: func_out = ADDER_OUT;
			6'b10_01??: func_out = LOGIK_OUT;
			6'b10_10??: func_out = SLT_OUT;
              JR: func_out = 'hx;     //JR decode in functional, but dont do any operation with alu
                                      //wrong_instr_func must not heppend if we have JR
			default: wrong_instr_func = 1'b1;
		endcase
	end
	
endmodule 
