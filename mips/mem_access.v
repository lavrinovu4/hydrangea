//////////////////////////////////////////////////////////////////////////////////
//Description:stage of memory access 					                                	//
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ps

module mem_access(i_clk, i_arst_n, i_dw_en, i_dsrs_out, i_daddr, i_din, o_dout,
			i_eret_ex, i_rw_en_ex, i_raddr_w_ex, o_eret_ma, o_rw_en_ma, o_raddr_w_ma,
      o_valid_ma, o_wr_addr_data, i_ma_kill,
      i_copr_dout);

	parameter DATA_WIDTH = 32;
	parameter DATA_ADDR_WIDTH = 32;       //width data memory gates
	parameter ADDR_REG = 5;               //width general purpose registers
  parameter PC_WIDTH = 30;
	
	//Port declarations
	input                           i_clk;
	input                           i_arst_n;
	input                           i_dw_en;         //data write enable
	input [1:0]                     i_dsrs_out;      //source out of this stage
	input [DATA_WIDTH - 1 : 0]      i_daddr;         //address for data memory
	input [DATA_WIDTH - 1 : 0]      i_din;
  input [DATA_WIDTH - 1 : 0]      i_copr_dout;

	output reg [DATA_WIDTH - 1 : 0] o_dout;

  //for next stage
  input                           i_eret_ex;
	input                           i_rw_en_ex;
	input [ADDR_REG - 1 : 0]        i_raddr_w_ex;

  output reg                       o_eret_ma;
	output reg                      o_rw_en_ma;       //register write enable
	output reg [ADDR_REG - 1 : 0]   o_raddr_w_ma;     //register address write 

  output                          o_valid_ma;       //command done on previos stages? no - 1
  output                          o_wr_addr_data;
  input                           i_ma_kill;        //from coprocessor
  
	//---------------------------Internal variables----------------------------
	wire [DATA_WIDTH - 1 :0] dout;
  wire                     w_en;
  wire                     wr_addr_lw;

  localparam  ALU_OUT = 2'b00,
              MEM_DATA_OUT = 2'b01,
              COPR_OUT = 2'b10;	

  //---------------------------Variable assigments---------------------------
  assign o_valid_ma = i_dw_en | (i_rw_en_ex & (|i_raddr_w_ex));

  assign wr_addr_lw = i_daddr[1] | i_daddr[0];
  assign o_wr_addr_data = i_dw_en & wr_addr_lw;
  assign w_en = i_dw_en & !wr_addr_lw;

	//---------------------------Code starts-----------------------------------
	//data memory for simulation
  data_mem #(
		.DATA_ADDR_WIDTH 	( DATA_ADDR_WIDTH	- 2),
		.DATA_WIDTH 			( DATA_WIDTH 		))
	 u_data_mem(
		.i_clk 			( i_clk	 	                          ),
		.i_address 	( i_daddr[DATA_ADDR_WIDTH - 1 : 2]	),
		.i_w_en 		( w_en	                            ),
		.i_din 			( i_din 	                          ),
		.o_dout 		( dout		                          ));

   //generate memory access out
	 always @(posedge i_clk, negedge i_arst_n) begin
	 	if(!i_arst_n)
	 		o_dout <= 0;
	 	else begin
      case(i_dsrs_out)
	 			ALU_OUT:o_dout <= i_daddr;
	 			MEM_DATA_OUT:o_dout <= dout;
        COPR_OUT: o_dout <= i_copr_dout;
      endcase
	 	end
	 end

   //control signal for write back stage
	 always @(posedge i_clk, negedge i_arst_n) begin
	 	if(!i_arst_n) begin
	 		o_rw_en_ma <= 0;
	 		o_raddr_w_ma <= 0;
    end else if(i_ma_kill) begin //when we have interrupt
      o_rw_en_ma <= 0;
      o_raddr_w_ma <= 0;
	 	end else begin
	 		o_rw_en_ma <= i_rw_en_ex;
	 		o_raddr_w_ma <= i_raddr_w_ex;
	 	end
	 end

  always @(posedge i_clk, negedge i_arst_n) begin
    if(!i_arst_n)
      o_eret_ma <= 0;
    else
      o_eret_ma <= i_eret_ex;
  end

endmodule
