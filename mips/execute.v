//////////////////////////////////////////////////////////////////////////////////////////////////
//Description: stage execute - alu 																															//
//////////////////////////////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ps

module execute(i_clk, i_arst_n, i_alu_ctrl, i_data_a, i_data_b, i_immediate, i_sa, i_srs_b, 
    i_pc_de_ex, i_pc_de, i_pc_branch_imm, i_beq_en, i_bne_en,
		o_alu_result, o_dout_b, o_pc_branch, o_branch_en, o_ovf_flag,
		i_eret_de, i_dw_en_de, i_dsrs_out_de, i_rw_en_de, i_raddr_w_de,
		o_eret_ex, o_dw_en_ex, o_dsrs_out_ex, o_rw_en_ex, o_raddr_w_ex,
    o_pc_ex_ma, o_valid_ex, i_ex_kill);

	parameter ALU_CTRL_WIDTH    = 5;                         
	parameter DATA_WIDTH        = 32;                            
  parameter INSTR_ADDR_WIDTH  = 30;
  parameter PC_WIDTH          = INSTR_ADDR_WIDTH - 2; 
	parameter REG_ADDR_WIDTH    = 5;                       //width general purpose registers
	`include "func.v"                                      //for log();
	localparam ADDR_WIDTH_DATA  = log(2, DATA_WIDTH);      //for width amount of shifter

	//Port declarations
	input                          			  i_clk;
	input                          			  i_arst_n;
	input [ALU_CTRL_WIDTH - 1 : 0] 			  i_alu_ctrl;
	input [DATA_WIDTH - 1 : 0]     			  i_data_a;
	input [DATA_WIDTH - 1 : 0]     			  i_data_b;
	input [DATA_WIDTH - 1 : 0]     			  i_immediate;
	input [ADDR_WIDTH_DATA - 1 : 0]			  i_sa;           //shift amount
	input                          			  i_srs_b;        //sourse of portb alu

  input                                 i_beq_en;
  input                                 i_bne_en;
  input [PC_WIDTH - 1 : 0]              i_pc_de;        //pc for generating branch jmp
  input [PC_WIDTH - 1 : 0]       			  i_pc_de_ex;     //epc
  input [PC_WIDTH - 1 : 0]              i_pc_branch_imm; //take from instruction in decode for generating branch jmp

	output reg [DATA_WIDTH - 1 : 0]       o_alu_result;
	output reg [DATA_WIDTH - 1 : 0]       o_dout_b;       //repeat i_data_b
  output     [PC_WIDTH - 1 : 0]         o_pc_branch;   //new pc if we have branch
  output                                o_branch_en;
	output                                o_ovf_flag;      //overflow flag

  //control signal for next stages
  input                                 i_eret_de;
	input                          			  i_dw_en_de;
	input [1 : 0]                  			  i_dsrs_out_de;
	input                           		  i_rw_en_de;
	input [REG_ADDR_WIDTH - 1 : 0]        i_raddr_w_de;

  output reg                            o_eret_ex;
	output reg                            o_dw_en_ex;     //write enable to memory data
	output reg [1 : 0]                    o_dsrs_out_ex;  //sourse out of stage memory access
	output reg                            o_rw_en_ex;     //register write enable
	output reg [REG_ADDR_WIDTH - 1 : 0]   o_raddr_w_ex;   //register write address

  input                                 i_ex_kill;
  
  output reg [PC_WIDTH - 1 : 0]	        o_pc_ex_ma;
  output                                o_valid_ex;
	//----------------------------------Internal variables--------------------------------------
  parameter SRS_ALU_B = 0,
            SRS_ALU_IMMEDIATE = 1;

	reg  [DATA_WIDTH - 1 : 0] alu_b;                //data in b for alu
	wire [DATA_WIDTH - 1 : 0] alu_result_nxt;       //result of alu wire combinatiol
	wire zero_flag;

  //----------------------------------Variable assigments-------------------------------------
  assign o_pc_branch = i_pc_de + i_pc_branch_imm;
  assign o_branch_en = (i_beq_en & zero_flag) | (i_bne_en & !zero_flag);

  assign o_valid_ex = (i_rw_en_de & (0 != i_raddr_w_de)) | i_dw_en_de | o_branch_en;

	//----------------------------------Code starts---------------------------------------------
	always @* begin
    alu_b = 'hx;
    case(i_srs_b)
      SRS_ALU_B:            alu_b = i_data_b;
      SRS_ALU_IMMEDIATE:    alu_b = i_immediate;
    endcase
	end

	alu #(
		.ALU_CTRL_WIDTH		( ALU_CTRL_WIDTH ))
	 u_alu( 
		.i_operation 		( i_alu_ctrl     	),
		.i_data_a 			( i_data_a	    	),
		.i_data_b 			( alu_b			    	),
		.i_sa						( i_sa 			    	),
		.o_dout 				( alu_result_nxt  ),
		.o_zero_flag		( zero_flag	    	),
		.o_ovf_flag 		( o_ovf_flag     	));

  //generate execute out
	always @(posedge i_clk, negedge i_arst_n) begin
		if(!i_arst_n) begin
			o_alu_result <= 0;
			o_dout_b <= 0;
		end else begin
			o_alu_result <= alu_result_nxt;
			o_dout_b <= i_data_b;
		end
	end

  //control signal for next stages(decode & write back)
	always @(posedge i_clk, negedge i_arst_n) begin
		if(!i_arst_n) begin
			o_dw_en_ex <= 0;
			o_dsrs_out_ex <= 0;
			o_rw_en_ex <= 0;
			o_raddr_w_ex <= 0;   
    end else if(i_ex_kill) begin
      o_dw_en_ex <= 0;
      o_rw_en_ex <= 0;
      o_raddr_w_ex <= 0;
		end else begin
			o_dw_en_ex <= i_dw_en_de;
			o_dsrs_out_ex <= i_dsrs_out_de;
			o_rw_en_ex <= i_rw_en_de;
			o_raddr_w_ex <= i_raddr_w_de;
		end
	end

  always @(posedge i_clk, negedge i_arst_n) begin
    if(!i_arst_n)
      o_eret_ex <= 0;
    else
      o_eret_ex <= i_eret_de;
  end
  
  //for epc
	always @(posedge i_clk, negedge i_arst_n) begin
		if(!i_arst_n)
      o_pc_ex_ma <= 0;                     
    else
      o_pc_ex_ma <= i_pc_de_ex;
 end
 
 
endmodule
