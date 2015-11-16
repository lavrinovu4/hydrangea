// Test wb slave

`timescale 1ns / 1ps

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
	input [3:0]	i_wb_sel;
	input	[31:0]  i_wb_adr;
	input	[31:0]	i_wb_dat;
	input											i_wb_cyc;
	input											i_wb_stb;
	
	output	[31:0]	o_wb_dat;
	output											o_wb_ack;																		
	
	////////////////////////////////////////
	reg	[3:0] delay_count;

	////////////////////////////////////////
	
	always @(posedge i_ck, negedge i_rb) begin
		if(!i_rb)
			delay_count <= 4'h0;
		else begin
			if(o_wb_ack)
				delay_count <= 4'h0;
			else if(i_wb_stb)
				delay_count <= delay_count + 4'h1;
		end
	end

	assign o_wb_ack = i_wb_stb && delay_count[0];

	data_mem u_data_mem (
		.i_clk			(i_ck),
		.i_address	(i_wb_adr),
		.i_sel_width(i_wb_sel),
		.i_w_en			(i_wb_stb & i_wb_we),
		.i_din			(i_wb_dat),
		.o_dout			(o_wb_dat));

 endmodule
		
		
		
		
