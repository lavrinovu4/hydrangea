/////////////////////////////////////////////////////////////////////////////
//Desription: shifter - sll, srl, sra, ror			    			   	   //
/////////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ps

module shifter(i_operation, i_amount, i_din, o_dout);
	parameter DATA_WIDTH = 32;
	`include "func.v"                                 //for log();
	localparam ADDR_WIDTH 		= log(2, DATA_WIDTH);   //for width amount 
	localparam DATA_EXT_WIDTH 	= 2 * DATA_WIDTH;     //it will extend twice

	//Port declarations
	input 	[1 : 0]					i_operation;
	input 	[ADDR_WIDTH - 1 : 0]	i_amount;
	input 	[DATA_WIDTH - 1 : 0] 	i_din;
	output	[DATA_WIDTH - 1 : 0] 	o_dout;

	//-----------------------Internal variables------------------
	wire 	[DATA_WIDTH - 2 : 0]		zero_ext;
	wire 	[DATA_WIDTH - 2 : 0]		sign_ext;
	wire	[ADDR_WIDTH - 1 : 0]		sll_true_ext;

	reg		[DATA_EXT_WIDTH - 2 : 0]	din_ext;
	wire 	[DATA_EXT_WIDTH - 2 : 0] 	dout_ext;

	`include "local_params.v"
	
	//-----------------------Variable assigments-----------------
	assign zero_ext 	= { DATA_WIDTH - 1 { 1'b0 				   }};
	assign sign_ext 	= { DATA_WIDTH - 1 { i_din[DATA_WIDTH - 1] }};
	assign sll_true_ext = { ADDR_WIDTH 	 { SLL == i_operation    }};
	
	assign dout_ext 	= din_ext >> (i_amount ^ sll_true_ext);   //shift left(sllu_true turn to shift right)
	assign o_dout 		= dout_ext[DATA_WIDTH - 1 : 0];

	//-----------------------Code start--------------------------
	//extender for shifter
	always @* begin	
		din_ext = 'hx;		
		case(i_operation)
			SLL: din_ext = {i_din, zero_ext};
			ROR: din_ext = {i_din[DATA_WIDTH - 2 : 0], i_din};
			SRL: din_ext = {zero_ext, i_din};
			SRA: din_ext = {sign_ext, i_din};
		endcase
	end

endmodule


/*
=======it is the same realization of shift right -- somewhere it will be usefull
================================================================================

	//generate 5 multiplexors(ADDR_WIDTH = 5), which do shift
	generate
		for(i = 0; i < ADDR_WIDTH; i = i + 1) begin : shift
			localparam SHIFT_WIDTH_BITS 	= 2**(ADDR_WIDTH - i - 1);
			localparam PREV_SHIFT_OUT_WIDTH = DATA_WIDTH + 2**(ADDR_WIDTH - i);
			localparam SHIFT_OUT_WIDTH 		= PREV_SHIFT_OUT_WIDTH - SHIFT_WIDTH_BITS;

			reg [SHIFT_OUT_WIDTH - 1 : 0]			shift_out;
			wire [PREV_SHIFT_OUT_WIDTH - 1  : 0] 	shift_out_prev;
			wire 									shift_en;			//enable shift right

			//on first iteration choose ext_data
			if(!i)
				assign shift_out_prev = ext_data;
			else
				assign shift_out_prev = shift[i - 1].shift_out;

			//decode it needs shift(i_shift_amount) & what direction(sll_true)
			//Left direction determinate of inversion all signal of i_shift_amount
			if(1 == (ADDR_WIDTH - i))
				assign shift_en = i_shift_amount[ADDR_WIDTH - i - 1];
			else
				assign shift_en = sll_true ^ i_shift_amount[ADDR_WIDTH - i - 1];

			always @* begin
				if(shift_en)
					shift_out = {shift_out_prev[PREV_SHIFT_OUT_WIDTH - 1 : SHIFT_OUT_WIDTH],  shift_out_prev[SHIFT_OUT_WIDTH - 1  : SHIFT_WIDTH_BITS]};
				else
					shift_out = {shift_out_prev[SHIFT_OUT_WIDTH - 1      : SHIFT_WIDTH_BITS], shift_out_prev[SHIFT_WIDTH_BITS - 1 : 0]};
			end

		end
	endgenerate

*/
