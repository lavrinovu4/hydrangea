// Test wb slave

`timescale 1ns / 1ps

`define WB_DWIDTH 32
`define WB_SWIDTH 4
`define WB_AWIDTH 30

module wb_slave_test (
														i_ck,
														i_rb,

													  i_wb_we,
  													i_wb_sel,
														i_wb_adr,
														i_wb_dat,
														i_wb_cyc,
														i_wb_stb,
														o_wb_dat,
														o_wb_ack
																				);

	input										i_ck;
	input										i_rb;

	input 										i_wb_we;
	input [`WB_SWIDTH - 1:0]	i_wb_sel;
	input	[`WB_AWIDTH - 1:0]  i_wb_adr;
	input	[`WB_DWIDTH - 1:0]	i_wb_dat;
	input											i_wb_cyc;
	input											i_wb_stb;

	output	[`WB_DWIDTH - 1:0]	o_wb_dat;
	output											o_wb_ack;

	////////////////////////////////////////

	wire start_write;
	wire start_read;
	reg start_read_r;
	reg start_write_r;

	assign start_write = i_wb_stb &&  i_wb_we && !start_read_r;

	always @( posedge i_ck, negedge i_rb )
		if(!i_rb)
			start_read_r <= 1'b0;
		else
    	start_read_r <= start_read;

	always @( posedge i_ck, negedge i_rb )
		if(!i_rb)
			start_write_r <= 1'b0;
		else
    	start_write_r <= start_write;

	assign start_read  = i_wb_stb && !i_wb_we && !start_read_r && !start_write_r;
	assign o_wb_ack    = i_wb_stb && ( start_write || start_read_r );

	memory u_mem (
		.i_clk			(i_ck),
		.i_address	(i_wb_adr),
		.i_sel_width(i_wb_sel),
		.i_w_en			(start_write),
		.i_din			(i_wb_dat),
		.o_dout			(o_wb_dat));

 endmodule



