//////////////////////////////////////////////////////////////////////////
//Desription:32-bit alu with func:                                      //
//		adder:add, addu, sub, subu                                        //
//		slt, sltu                                                         //
//		shifter: sll, srl, sra, ror                                       //
//		logic: and, or, nor, xor            	                            //
//////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ps

module alu(i_operation, i_data_a, i_data_b, i_sa,
		      	o_dout, o_zero_flag, o_ovf_flag);

	parameter DATA_WIDTH 		= 32;
	`include "func.v"
	localparam AMOUNT_WIDTH = log(2, DATA_WIDTH);

	//Port declarations
	input 			[5 : 0]									 	i_operation;
	input 			[DATA_WIDTH - 1 : 0] 		  i_data_a;
	input 			[DATA_WIDTH - 1 : 0] 		  i_data_b;
	input 			[AMOUNT_WIDTH - 1 : 0] 		i_sa;          //shift amount
	output reg 	[DATA_WIDTH - 1 : 0] 	   	o_dout;
	output 	                             	o_zero_flag;
	output                               	o_ovf_flag;    //signed overlow

	//--------------------------Internal variables------------------------	

  //use for signed slt
	wire signed [DATA_WIDTH - 1 : 0]	  s_data_a;  
	wire signed [DATA_WIDTH - 1 : 0]	  s_data_b;

	wire 			  [DATA_WIDTH - 1 : 0] 	  adder_din_b;

	wire    		[DATA_WIDTH - 1 : 0]	  shifter_out;
	reg		    	[DATA_WIDTH - 1 : 0]	  logik_out;
	wire	    	[DATA_WIDTH : 0]		    adder_out;
	reg 		    						            slt_out;

	reg  			    					            sub_true;
	wire 	    	[DATA_WIDTH - 1 : 0] 	  sub_true_ext;
	wire 	    	[DATA_WIDTH - 1 : 0] 	  or_out;

	wire 	    	[5 : 2]							 	  alu_sel;
	wire 	    	[1 : 0]					        op_sel;

	reg 	    	[1 : 0] 				        srs_amount;
	reg 	    	[AMOUNT_WIDTH - 1 : 0]	amount;

	`include "local_params.v"

	//--------------------------Variable assigments-----------------------
	assign o_zero_flag 	= !o_dout;
  assign o_ovf_flag = (alu_sel == ADDER_OUT) & 
                      ((op_sel == ADD) | (op_sel == SUB)) & 
											(adder_out[DATA_WIDTH] ^ adder_out[DATA_WIDTH - 1]);

	assign or_out 	= i_data_a | i_data_b;

  //therefore our data became signed & we can use signed operation
	assign s_data_a = i_data_a;   
	assign s_data_b = i_data_b;

	assign {alu_sel, op_sel} = i_operation;


	assign sub_true_ext = { DATA_WIDTH { sub_true }};
	assign adder_din_b = i_data_b ^ sub_true_ext;       //invert din if we must make sub

  //we make adder a bit wider, because we need to know or we have signed overflow
  //msb bit of adder_out says we have signed overflow or not
	assign adder_out = {i_data_a[DATA_WIDTH - 1], i_data_a} + {adder_din_b[DATA_WIDTH - 1], adder_din_b} + sub_true;

	//--------------------------Code start--------------------------------
	always @* begin 
		o_dout = adder_out;
		case(alu_sel)
			SHIFT_OUT, 
				SHIFT_CONSTANT_OUT, 
				LUI_OUT:        	o_dout = shifter_out;
			LOGIK_OUT:	        o_dout = logik_out;
			ADDER_OUT: 	        o_dout = adder_out;
			SLT_OUT: 	          o_dout = {31'b0, slt_out};
		endcase
	end

  //function:set less then
  //if a<b then out=1 
	always @* begin
		slt_out = 'bx;
		case(op_sel)
			SLT: 	slt_out	= s_data_a < s_data_b; //todo: sometime make more effective slt
			SLTU:	slt_out	= i_data_a < i_data_b; 
		endcase
	end

  //control universal adder(make sub)
	always @* begin
		sub_true = 1'b0;
 		case(op_sel) 
			SUBU:	sub_true = 1'b1;
 			SUB:	sub_true = 1'b1;
 		endcase
	end

  //logic operation
	always @* begin
		logik_out = 'hx;
		case(op_sel)
			AND: 	logik_out = i_data_a & i_data_b;
			OR: 	logik_out = or_out;
			XOR: 	logik_out = i_data_a ^ i_data_b;
			NOR: 	logik_out = ~or_out;
		endcase
	end

  //srs for shift amount of shifter
	always @* begin
		amount = 'h0;
		case(alu_sel)
			SHIFT_OUT:	        	amount = i_data_a[AMOUNT_WIDTH - 1 : 0]; 
			SHIFT_CONSTANT_OUT: 	amount = i_sa;
			LUI_OUT:	            amount = 5'd16;
		endcase
	end

	shifter u_shifter(
		.i_operation	( op_sel 		  ),
		.i_amount 		( amount		  ),
		.i_din 			  ( i_data_b		),
		.o_dout 		  ( shifter_out ));

endmodule
