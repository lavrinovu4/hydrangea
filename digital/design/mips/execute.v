//////////////////////////////////////////////////////////////////////////////////////////////////
//Description: stage execute - alu 																															//
//////////////////////////////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ps

module execute(i_clk, i_arst_n, i_stall_en,
		i_alu_ctrl, i_data_a, i_data_b, i_immediate, i_sa, i_srs_b, 
    i_pc_de, i_beq_en, i_bne_en, i_sign_bit, i_nozero,
		o_alu_result, o_dout_b, o_branch_en, o_pc_branch,
		i_dw_en_de, i_dr_en_de, i_dsrs_out_de, i_dsel_width_de, 
		i_rw_en_de, i_raddr_w_de,
		o_dw_en_ex, o_dr_en_ex, o_dsrs_out_ex, o_dsel_width_ex, 
		o_rw_en_ex, o_raddr_w_ex,
    o_pc_ex,
		i_sec_alu_en, i_sel_sec_alu, i_sec_alu_op,
		i_int_only, o_delay_slot,
		o_div_zero, o_ovf_flag, o_wr_addr_data,
		o_stall_en_ex);

	parameter DATA_WIDTH        = 32;                            
  parameter INSTR_ADDR_WIDTH  = 30;
  parameter PC_WIDTH          = INSTR_ADDR_WIDTH - 2; 
	parameter REG_ADDR_WIDTH    = 5;                       //width general purpose registers
	`include "func.v"                                      //for log();
	localparam ADDR_WIDTH_DATA  = log(2, DATA_WIDTH);      //for width amount of shifter

	//Port declarations
	input                          			  i_clk;
	input                          			  i_arst_n;
	input 																i_stall_en;
	input [5 : 0]									 			  i_alu_ctrl;
	input [DATA_WIDTH - 1 : 0]     			  i_data_a;
	input [DATA_WIDTH - 1 : 0]     			  i_data_b;
	input [DATA_WIDTH - 1 : 0]     			  i_immediate;
	input [ADDR_WIDTH_DATA - 1 : 0]			  i_sa;           //shift amount
	input                          			  i_srs_b;        //sourse of portb alu

  input                                 i_beq_en;
  input                                 i_bne_en;
  input                                 i_sign_bit;
  input                                 i_nozero;
 	input [PC_WIDTH - 1 : 0]       			  i_pc_de;     //epc

	input 																i_sec_alu_en;
	input 																i_sel_sec_alu;
	input [2 : 0] 												i_sec_alu_op;  
  
	output reg [DATA_WIDTH - 1 : 0]       o_alu_result;
	output reg [DATA_WIDTH - 1 : 0]       o_dout_b;       //repeat i_data_b
  output                                o_branch_en;
	output [31 : 0] 											o_pc_branch;

	input 																i_int_only;
	output reg														o_delay_slot;

	output                                o_ovf_flag;      //overflow flag
	output 																o_div_zero;			//division zero
	output 																o_wr_addr_data;

  //control signal for next stages
	input                          			  i_dw_en_de;
	input                          			  i_dr_en_de;
	input [1 : 0]                  			  i_dsrs_out_de;
	input [2 : 0]                  			  i_dsel_width_de;
	input                           		  i_rw_en_de;
	input [REG_ADDR_WIDTH - 1 : 0]        i_raddr_w_de;

	output reg                            o_dw_en_ex;     //write enable to memory data
	output reg                            o_dr_en_ex;     //read enable to memory data
	output reg [1 : 0]                    o_dsrs_out_ex;  //sourse out of stage memory access
	output reg [2 : 0]                    o_dsel_width_ex;
	output reg                            o_rw_en_ex;     //register write enable
	output reg [REG_ADDR_WIDTH - 1 : 0]   o_raddr_w_ex;   //register write address

  output reg [PC_WIDTH - 1 : 0]	        o_pc_ex;

	output 																o_stall_en_ex;  
	//----------------------------------Internal variables--------------------------------------
	`include "local_params.v"

	reg  [DATA_WIDTH - 1 : 0] alu_b;                //data in b for alu
	wire [DATA_WIDTH - 1 : 0] alu_result_nxt;       //result of alu wire combinatiol
	wire zero_flag;
	wire sec_alu_busy;
	wire [DATA_WIDTH - 1 : 0] sec_alu_out;

	wire en_execute;
	wire kill_execute;

	//----------------------------------Code starts---------------------------------------------
	
	assign en_execute = ~i_stall_en;
	assign kill_execute = en_execute & (i_int_only | o_stall_en_ex | o_wr_addr_data | o_ovf_flag | o_div_zero);

  assign o_branch_en = (i_beq_en & zero_flag) | (i_bne_en & ~zero_flag) | (i_sign_bit & ~(i_nozero & zero_flag));
	assign o_pc_branch = i_immediate + i_pc_de;
	
	//i_sec_alu_en is setting up if we will work with second alu
	assign o_stall_en_ex = sec_alu_busy & i_sec_alu_en;

	always @* begin
    alu_b = 'hx;
    case(i_srs_b)
      REG_PORT_B:   alu_b = i_data_b;
      IMMEDIATE:    alu_b = i_immediate;
    endcase
	end

	alu u_alu( 
		.i_operation 		( i_alu_ctrl     	),
		.i_data_a 			( i_data_a	    	),
		.i_data_b 			( alu_b			    	),
		.i_sa						( i_sa 			    	),
		.o_dout 				( alu_result_nxt  ),
		.o_zero_flag		( zero_flag	    	),
		.o_ovf_flag 		( o_ovf_flag     	));

	additional_alu u_alu_mult_div(
		.i_clk					(i_clk),
		.i_arst_n				(i_arst_n),
		.i_en						(i_sec_alu_en),
		.i_operation		(i_sec_alu_op),
		.i_data_a				(i_data_a),		
		.i_data_b				(i_data_b),
		.o_dout					(sec_alu_out),
		.o_busy					(sec_alu_busy),
		.o_div_zero			(o_div_zero));

  //generate execute out
	always @(posedge i_clk, negedge i_arst_n) begin
		if(!i_arst_n) begin
			o_alu_result <= 0;
			o_dout_b <= 0;
		end else if(en_execute) begin
			o_alu_result <= i_sel_sec_alu == SEC_ALU ? sec_alu_out : alu_result_nxt;
			o_dout_b <= i_data_b;
		end
	end

  //control signal for next stages(decode & write back)
	always @(posedge i_clk, negedge i_arst_n) begin
		if(!i_arst_n) begin
			o_dw_en_ex <= 0;
			o_dr_en_ex <= 0;
			o_dsrs_out_ex <= 0;
			o_dsel_width_ex <= 0;
			o_rw_en_ex <= 0;
			o_raddr_w_ex <= 0;   
    end else if(kill_execute) begin
      o_dw_en_ex <= 0;
      o_dr_en_ex <= 0;
      o_rw_en_ex <= 0;
		end else if(en_execute) begin
			o_dw_en_ex <= i_dw_en_de;
			o_dr_en_ex <= i_dr_en_de;
			o_rw_en_ex <= i_rw_en_de;
			
			o_dsrs_out_ex <= i_dsrs_out_de;
			o_dsel_width_ex <= i_dsel_width_de;
			o_raddr_w_ex <= i_raddr_w_de;
		end
	end
  
  assign o_wr_addr_data = (i_dw_en_de | i_dr_en_de) & ((|alu_result_nxt[1:0] & (i_dsel_width_de == WORD)) | alu_result_nxt[0] & (i_dsel_width_de == HALFWORD));
  
	//for epc
	always @(posedge i_clk, negedge i_arst_n) begin
		if(!i_arst_n) begin
      o_pc_ex <= 0;                     
			o_delay_slot <= 0;
    end else if(en_execute) begin
			o_delay_slot <= o_branch_en;
      o_pc_ex <= i_pc_de;
		end
 end
 
 
endmodule
