/////////////////////////////////////////////////////////////////////
//Desription:memory for data	  				                           //
/////////////////////////////////////////////////////////////////////

`timescale 1ns/1ps

module data_mem(i_clk, i_address, i_w_en, i_din, o_dout);

	parameter DATA_WIDTH = 32;
	parameter DATA_ADDR_WIDTH = 32;

	//Port declarations
	input 				                    	i_clk;
	input 	[DATA_ADDR_WIDTH - 1 : 0] 	i_address;
	input 			                    		i_w_en;
	input 	[DATA_WIDTH - 1 : 0] 	    	i_din;
	output 	[DATA_WIDTH - 1 : 0] 	     	o_dout;

	//----------------------Internal variables---------------------
	reg  [DATA_WIDTH - 1 : 0] mem_data [2**DATA_ADDR_WIDTH - 1 : 0];

	//----------------------Variable assigments--------------------
	//async read
  assign o_dout = mem_data[i_address];
	//----------------------Code start-----------------------------
  //sync write
 	always @(posedge i_clk) begin
		if(i_w_en)
			mem_data[i_address] <= i_din;
	end

endmodule
