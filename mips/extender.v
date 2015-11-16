//////////////////////////////////////////////////////////////////////////
//Desription: extender-				 						                        			//
//					zero-extension									                          	//
//					sign-extension									                          	//
//////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ps

module extender(i_operation, i_din, o_dout);

	parameter DATA_WIDTH = 16;
	parameter DATA_EXT_WIDTH = 32;

	//Port declarations
	input 			 	            				i_operation;
	input 	[DATA_WIDTH - 1 : 0]   		i_din;
	output	[DATA_EXT_WIDTH- 1 : 0] 	o_dout;

	localparam DATA_DIFF_WIDTH = DATA_EXT_WIDTH - DATA_WIDTH;
	//----------------------Internal assigments-----------------------
	wire 		              					bit_extension;
	wire [DATA_DIFF_WIDTH - 1 : 0] 	extension;
	//----------------------Variable assigments-----------------------
	
	//if i_extend_operation = 0 then result is 0 - zero-extension
	//if i_extend_operation = 1 then result depends bit i_din[DATA_WIDTH - 1] - sign-extension
	
	assign bit_extension = i_operation & i_din[DATA_WIDTH - 1];
	assign extension	 = { DATA_DIFF_WIDTH { bit_extension }};			
	assign o_dout	 = { extension, i_din };
	
endmodule
