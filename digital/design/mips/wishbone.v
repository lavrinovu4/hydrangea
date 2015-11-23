module wishbone(o_wb_cyc, o_wb_stb, o_wb_sel, o_wb_we, o_wb_adr, o_wb_dat,
								i_wb_dat, i_wb_ack,
								
								i_clk, i_rb, 
								i_address_mem1, i_req_mem1, o_data_mem1, o_ack_mem1,
								i_address_mem2, i_req_mem2, i_sel_mem2, o_data_mem2, i_wr_mem2, i_data_mem2, o_ack_mem2);


	localparam AWIDTH = 30;
	localparam DWIDTH = 32;

input 							i_clk;
input 							i_rb;

	input 									i_req_mem1;
	input  [AWIDTH - 1 : 0] i_address_mem1;
	output [DWIDTH - 1 : 0] o_data_mem1;
	output 									o_ack_mem1;

	input 									i_req_mem2;
	input  [AWIDTH - 1 : 0] i_address_mem2;
	input 									i_wr_mem2;
	input  [3 : 0]					i_sel_mem2;
	input  [DWIDTH - 1 : 0] i_data_mem2;
	output [DWIDTH - 1 : 0] o_data_mem2;
	output 									o_ack_mem2;

input	 							i_wb_ack;
input [31 : 0] 			i_wb_dat;
output 							o_wb_cyc;
output 							o_wb_stb;
output 							o_wb_we;
output [3 : 0] 			o_wb_sel;
output [31 : 0] 		o_wb_adr;
output [31 : 0] 		o_wb_dat;

	reg current_port;  //0 - port1, 1 - port2

	reg [DWIDTH - 1 : 0] data_mem1_ff;
	reg [DWIDTH - 1 : 0] data_mem2_ff;


	wire      	mem1_cache_ack  ;
	wire [31:0] mem1_cache_data ;
	wire      	mem1_cache_req  ;
	wire [29:0] mem1_cache_addr ;

//=====================================================================================
//Code  over here

cache_ro icache (
  .i_ck            ( i_clk ),
  .i_rb            ( i_rb ),

  .i_cache_addr    ( i_address_mem1 ),
  .i_cache_req     ( i_req_mem1 		),

  .o_cache_data    ( o_data_mem1 	  ),
  .o_cache_ack     ( o_ack_mem1 	  ),

  .i_mem_ack       ( mem1_cache_ack ),
  .i_mem_data      ( mem1_cache_data ),
  .o_mem_req       ( mem1_cache_req  ),
  .o_mem_addr      ( mem1_cache_addr )
);

	assign o_wb_cyc = o_wb_stb;
/*
 * current_port mem1_cache_req i_req_mem2 i_wb_ack  current_port(next)
 *         0          0            0          0           0
 *         0          0            0          1           0
 *         0          0            1          0           1
 *         0          0            1          1           1
 *         0          1            0          0           0
 *         0          1            0          1           0
 *         0          1            1          0           0 (need to wait while ack receive)
 *         0          1            1          1           1
 *         1          0            0          0           1
 *         1          0            0          1           1
 *         1          0            1          0           1
 *         1          0            1          1           1
 *         1          1            0          0           0
 *         1          1            0          1           0
 *         1          1            1          0           1
 *         1          1            1          1           0 (need to wait while ack receive)
 */
	always @(posedge i_clk or negedge i_rb) begin
		if(!i_rb)
			current_port <= 1'b0;
		/*else if(i_wb_ack | ~(i_req_mem2 | mem1_cache_req))
			current_port <= i_req_mem2 & (~current_port | ~mem1_cache_req );*/
		else
			current_port <= (current_port & i_req_mem2 & ~i_wb_ack) |
											(~current_port & i_req_mem2 & i_wb_ack) |
											(~mem1_cache_req & i_req_mem2) |
											(~mem1_cache_req & current_port);
	end
	
	assign o_wb_stb = 		current_port == 1'b1 ? i_req_mem2 		: mem1_cache_req ;
	assign o_wb_we = 			current_port == 1'b1 ? i_wr_mem2 			: 1'b0;
	assign o_wb_sel = 		current_port == 1'b1 ? i_sel_mem2 		: 4'b1111;
	assign o_wb_adr = 		current_port == 1'b1 ? i_address_mem2 : mem1_cache_addr;
	assign o_wb_dat = 		current_port == 1'b1 ? i_data_mem2 		: 32'h0;

	always @(posedge i_clk or negedge i_rb) begin
		if(!i_rb)
			data_mem1_ff <= 32'h0;
		else if(~current_port)
			data_mem1_ff <= i_wb_dat;
	end

	assign mem1_cache_data = current_port == 1'b1 ? data_mem1_ff : i_wb_dat;
	assign mem1_cache_ack = (current_port == 1'b0) & mem1_cache_req  & i_wb_ack;

	always @(posedge i_clk or negedge i_rb) begin
		if(!i_rb)
			data_mem2_ff <= 32'h0;
		else if(current_port)
			data_mem2_ff <= i_wb_dat;
	end

	assign o_data_mem2 = current_port == 1'b0 ? data_mem2_ff : i_wb_dat;
	assign o_ack_mem2 = (current_port == 1'b1) & i_req_mem2 & i_wb_ack;


endmodule
