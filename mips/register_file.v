///////////////////////////////////////////////////////////////////
//Desription:general purpose register 					         //
///////////////////////////////////////////////////////////////////

`timescale 1ns/1ps

module register_file(i_clk, i_addr_ra, i_addr_rb, i_w_en, i_addr_w, i_din,
						o_dout_ra, o_dout_rb);

	parameter DATA_WIDTH = 32;
	parameter REG_ADDR_WIDTH = 5;

	//Port Declarations
	input 				            		i_clk;
	input     	[REG_ADDR_WIDTH - 1 : 0] 	i_addr_ra;
	input     	[REG_ADDR_WIDTH - 1 : 0] 	i_addr_rb;
	input						            i_w_en;
	input     	[REG_ADDR_WIDTH - 1 : 0] 	i_addr_w;
	input     	[DATA_WIDTH - 1 : 0] 	   	i_din;
	output reg	[DATA_WIDTH - 1 : 0]    	o_dout_ra;
	output reg	[DATA_WIDTH - 1 : 0]     	o_dout_rb;

	//-----------------------Internal variables----------------
	reg [DATA_WIDTH - 1 : 0] registers [2**REG_ADDR_WIDTH - 1 : 1];

	//-----------------------Code start------------------------
  //async read port a
	always @* begin
		if(!i_addr_ra)
			o_dout_ra = 0;
		else
			o_dout_ra = registers[i_addr_ra];
	end

  //async read port a
	always @* begin
		if(!i_addr_rb)
			o_dout_rb = 0;
		else
			o_dout_rb = registers[i_addr_rb];
	end

  //sync write data
	always @(posedge i_clk) begin
		if(i_w_en)
			registers[i_addr_w] <= i_din;
	end

endmodule
