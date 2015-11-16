///////////////////////////////////////////////////////////////////
//Desription:not-synthesible memory for instruction	  	         //
///////////////////////////////////////////////////////////////////

`timescale 1ns/1ps

module instr_mem(i_address, o_instruction);
	parameter INSTR_ADDR_WIDTH = 26;
	localparam BYTE_WIDTH = 8;
	localparam INSTR_WIDTH = 4 * BYTE_WIDTH;

	//Port declarations
	input 	[31 : 0] 	i_address;
	output 	[INSTR_WIDTH - 1 : 0] 	  	o_instruction;
/*
	//-----------------Internal variables-----------------------
	reg [BYTE_WIDTH - 1 : 0] mem [2**INSTR_ADDR_WIDTH - 1 : 0];

	//-----------------Variable assigmens-----------------------
	assign o_instruction = { mem[i_address[INSTR_ADDR_WIDTH - 1 : 0]], 
                  				 mem[i_address[INSTR_ADDR_WIDTH - 1 : 0] + 1], 
				                   mem[i_address[INSTR_ADDR_WIDTH - 1 : 0] + 2], 
				                   mem[i_address[INSTR_ADDR_WIDTH - 1 : 0] + 3] };
*/

	reg [31 : 0] mem [2**20 - 1 : 0];

	assign o_instruction = mem[i_address[20 : 0]];

endmodule
