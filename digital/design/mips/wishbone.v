module wishbone(o_wb_cyc, o_wb_stb, o_wb_sel, o_wb_we, o_wb_adr, o_wb_dat,
								i_wb_dat, i_wb_ack,
								
								i_clk, i_arst_n, i_adr, i_we, i_re, i_din, i_sel, o_dout, o_ack);

input 							i_clk;
input 							i_arst_n;
input 							i_we;
input 							i_re;
input [3 : 0] 			i_sel;
input [29 : 0] 			i_adr;
input [31 : 0] 			i_din;
output [31 : 0] 		o_dout;
output 							o_ack;

input	 							i_wb_ack;
input [31 : 0] 			i_wb_dat;
output 							o_wb_cyc;
output 							o_wb_stb;
output 							o_wb_we;
output [3 : 0] 			o_wb_sel;
output [31 : 0] 		o_wb_adr;
output [31 : 0] 		o_wb_dat;

//---------------------------------------------------------------------------------

assign o_wb_cyc = i_we | i_re;
assign o_wb_stb = o_wb_cyc;

assign o_wb_we = i_we;
assign o_wb_sel = i_sel;

assign o_wb_adr = {2'b00, i_adr};
assign o_wb_dat = i_din;

assign o_dout = i_wb_dat;
assign o_ack = i_wb_ack;

endmodule
