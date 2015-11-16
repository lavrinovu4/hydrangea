///////////////////////////////////////////////////////////////////
//Desription:not-synthesible memory for instruction	  	         //
///////////////////////////////////////////////////////////////////

`timescale 1ns/1ps

module instr_mem(i_address, o_instruction);
	parameter INSTR_ADDR_WIDTH = 32;
	localparam BYTE_WIDTH = 8;
	localparam INSTR_WIDTH = 4 * BYTE_WIDTH;

	//Port declarations
	input 	[INSTR_ADDR_WIDTH - 1 : 0] 	i_address;
	output 	[INSTR_WIDTH - 1 : 0] 	  	o_instruction;

	//-----------------Internal variables-----------------------
	reg [INSTR_WIDTH/*BYTE_WIDTH*/ - 1 : 0] mem [2**INSTR_ADDR_WIDTH - 1 : 0];

	//-----------------Variable assigmens-----------------------
	assign o_instruction = mem[i_address[INSTR_ADDR_WIDTH-1:2]] /*{ mem[i_address], 
                  				 mem[i_address + 1], 
				                   mem[i_address + 2], 
				                   mem[i_address + 3] }*/;

	//----------------Test_bench code---------------------------
  `ifndef BOOT_FILE
	initial begin
    	$display("Load standart test file for simulation---------------------------------OK");
		$readmemh("t0.dat", mem);
  	end
  `endif

endmodule
