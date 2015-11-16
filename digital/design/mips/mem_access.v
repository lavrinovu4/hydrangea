//////////////////////////////////////////////////////////////////////////////////
//Description:stage of memory access 					                                	//
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ps

module mem_access(i_clk, i_arst_n, i_dw_en, i_dr_en, i_dsrs_out, i_dsel_width, 
			i_daddr, i_din, o_dout,
			i_rw_en_ex, i_raddr_w_ex, o_rw_en_ma, o_raddr_w_ma,
      i_copr_dout,
			o_adr, o_sel, o_we, o_re, o_din, i_dout, i_ack,
			o_stall_en_ma);

	parameter ADDR_REG = 5;               //width general purpose registers
  parameter PC_WIDTH = 30;
	
	//Port declarations
	input             i_clk;
	input             i_arst_n;
	input             i_dw_en;         //data write enable
	input             i_dr_en;         //data read enable
	input [1 : 0]     i_dsrs_out;      //source out of this stage
	input [2 : 0] 		i_dsel_width;
	input [31 : 0]    i_daddr;         //address for data memory
	input [31 : 0]    i_din;
  input [31 : 0]    i_copr_dout;

	output reg [31 : 0] o_dout;

  //for next stage
	input                           i_rw_en_ex;
	input [ADDR_REG - 1 : 0]        i_raddr_w_ex;

	output reg                      o_rw_en_ma;       //register write enable
	output reg [ADDR_REG - 1 : 0]   o_raddr_w_ma;     //register address write 


	output [29 : 0] 		o_adr;
	output [3 : 0] 			o_sel;
	output  						o_we;
	output  						o_re;
	output [31 : 0] 		o_din;
	input [31 : 0] 			i_dout;
	input 							i_ack;

	output 							o_stall_en_ma;
	
  
	//---------------------------Internal variables----------------------------
	wire [31 :0] 						 dout;
	reg  [3 : 0] 						 sel_width;
	reg	 [31 : 0] 					 din_nxt;
	reg	 [31 : 0] 					 dout_nxt;

	wire 											kill_mem_access;

  `include "local_params.v"

	assign o_stall_en_ma = (i_dw_en | i_dr_en) & ~i_ack;
	assign kill_mem_access = o_stall_en_ma;

  always @(i_daddr[1:0], i_dsel_width) begin
  	sel_width = 4'h0;
  	case(i_dsel_width)
  		BYTE, BYTE_UNS: 
  			case(i_daddr[1:0])
  				2'b00: sel_width = 4'b0001;
  				2'b01: sel_width = 4'b0010;
 			 		2'b10: sel_width = 4'b0100;
  				2'b11: sel_width = 4'b1000;
  		endcase
  		HALFWORD, HALFWORD_UNS: 
  			case(i_daddr[1])
  				1'b0: sel_width = 4'b0011;
 			 		1'b1: sel_width = 4'b1100;
  		endcase
  		WORD:
  			sel_width = 4'b1111;
			WORDLEFT: begin
				case(i_daddr[1 : 0])
					2'b00: sel_width = 4'b0001;
					2'b01: sel_width = 4'b0011;
					2'b10: sel_width = 4'b0111;
					2'b11: sel_width = 4'b1111;
				endcase
			end
			WORDRIGHT: begin
				case(i_daddr[1 : 0])
					2'b00: sel_width = 4'b1111;
					2'b01: sel_width = 4'b1110;
					2'b10: sel_width = 4'b1100;
					2'b11: sel_width = 4'b1000;
				endcase
			end
  	endcase
  end

	always @(i_din, i_dsel_width, i_daddr) begin
		din_nxt = i_din;
		case(i_dsel_width)
			BYTE:			din_nxt = {4{i_din[7 : 0]}};
			HALFWORD: din_nxt = {2{i_din[15 : 0]}};
			WORD:			din_nxt = i_din;
			WORDLEFT:	begin
				case(i_daddr[1 : 0])
					2'b00:din_nxt = {24'h0, i_din[31 : 24]};
					2'b01:din_nxt = {16'h0, i_din[31 : 16]};
					2'b10:din_nxt = {8'h0, i_din[31 : 8]};
					2'b11:din_nxt = i_din;
				endcase
			end
			WORDRIGHT:	begin
				case(i_daddr[1 : 0])
					2'b00:din_nxt = i_din; 
					2'b01:din_nxt = {i_din[23 : 0], 8'b0};
					2'b10:din_nxt = {i_din[15 : 0], 16'b0};
					2'b11:din_nxt = {i_din[7 : 0], 24'b0};
				endcase
			end
		endcase
	end

	assign o_adr = i_daddr[31 : 2];
	assign o_sel = sel_width;
	assign o_we = i_dw_en;
	assign o_re = i_dr_en;
	assign o_din = din_nxt;

	assign dout = i_dout;
	
	always @(dout, i_din, i_dsel_width, i_daddr) begin
		dout_nxt = dout;
		case(i_dsel_width)
			BYTE:			begin
				case(i_daddr[1 : 0])
 					2'b00: dout_nxt = {{24{dout[7]}}, dout[7 : 0]};
 					2'b01: dout_nxt = {{24{dout[15]}}, dout[15 : 8]};
					2'b10: dout_nxt = {{24{dout[23]}}, dout[23 : 16]};
					2'b11: dout_nxt = {{24{dout[31]}}, dout[31 : 24]};
				endcase
		 	end
			BYTE_UNS:			begin
				case(i_daddr[1 : 0])
 					2'b00: dout_nxt = {24'h0, dout[7 : 0]};
 					2'b01: dout_nxt = {24'h0, dout[15 : 8]};
					2'b10: dout_nxt = {24'h0, dout[23 : 16]};
					2'b11: dout_nxt = {24'h0, dout[31 : 24]};
				endcase
		 	end
		 	HALFWORD:	begin
				case(i_daddr[1])
					1'b0: dout_nxt = {{16{dout[15]}}, dout[15 : 0]};
					1'b1: dout_nxt = {{16{dout[31]}}, dout[31 : 16]};
				endcase
		 	end
		 	HALFWORD_UNS:	begin
				case(i_daddr[1])
					1'b0: dout_nxt = {16'h0, dout[15 : 0]};
					1'b1: dout_nxt = {16'h0, dout[31 : 16]};
				endcase
		 	end
		 	WORD: 		dout_nxt = dout;
		 	WORDLEFT: begin
				case(i_daddr[1 : 0])
					2'b00: dout_nxt = {dout[7 : 0], i_din[23 : 0]};
					2'b01: dout_nxt = {dout[15 : 0], i_din[15 : 0]};
					2'b10: dout_nxt = {dout[23 : 0], i_din[7 : 0]};
					2'b11: dout_nxt = dout;
				endcase
		 	end
			WORDRIGHT:begin
				case(i_daddr[1 : 0])
					2'b00: dout_nxt = dout;
					2'b01: dout_nxt = {i_din[31 : 24], dout[31 : 8]};
					2'b10: dout_nxt = {i_din[31 : 16], dout[31 : 16]};
					2'b11: dout_nxt = {i_din[31 : 8], dout[31 : 24]};
				endcase
			end
		endcase
	end

	 //generate memory access out
	 always @(posedge i_clk, negedge i_arst_n) begin
	 	if(!i_arst_n)
	 		o_dout <= 0;
	 	else begin
      case(i_dsrs_out)
	 			ALU_OUT:o_dout <= i_daddr;
	 			MEM_DATA_OUT:o_dout <= dout_nxt;
        COPR_OUT: o_dout <= i_copr_dout;
      endcase
	 	end
	 end

   //control signal for write back stage
	 always @(posedge i_clk, negedge i_arst_n) begin
	 	if(!i_arst_n) begin
	 		o_rw_en_ma <= 0;
	 		o_raddr_w_ma <= 0;
    end else begin
			
			if( kill_mem_access )
      	o_rw_en_ma <= 0;
	 		else begin
	 			o_rw_en_ma <= i_rw_en_ex;
	 			o_raddr_w_ma <= i_raddr_w_ex;
	 		end

		end
	 end

endmodule
