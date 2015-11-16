////////////////////////////////////////////////////////////
//Description: control for all mips depends opode         //
////////////////////////////////////////////////////////////

`timescale 1ns/1ps

module mips_cu(i_opcode, o_raddr_dst, o_dsrs_out, o_rw_en,
	o_dw_en, o_extend_operation, o_srs_alu_b, 
  o_jmp_en, o_beq_en, o_bne_en,
  o_wrong_instruction);
	
	parameter OPCODE_WIDTH = 6;

	//Port declarations
	input  [OPCODE_WIDTH - 1 : 0] 	i_opcode;               //operation code
	output reg 				          		o_jmp_en;
	output reg 				           		o_rw_en;                //register write enable
	output reg				          		o_raddr_dst;            //register address distination
	output reg 				          		o_extend_operation;     
	output reg        	          	o_srs_alu_b;
	output reg [1 : 0]           		o_dsrs_out;             //data sourse out for memory access
	output reg 					          	o_dw_en;                //data write enable
	output reg           						o_beq_en;
  output reg 						          o_bne_en;

  output reg                      o_wrong_instruction;
	

	//--------------------Internal variables--------------------
	`include "local_params.v"

  localparam  RT            = 1'b0,
              RD            = 1'b1;

  localparam  ALU_OUT       = 2'b00,
              MEM_DATA_OUT  = 2'b01,
              COPR_OUT      = 2'b10;

  localparam  ZERO_EXT      = 1'b0,
              SIGN_EXT      = 1'b1;

  localparam  REG_PORT_B    = 1'b0,
              IMMEDIATE     = 1'b1;
	//--------------------Code start----------------------------
	always @* begin
		o_raddr_dst = RT;
		o_dsrs_out = 2'bx;
		o_rw_en = 1'b0;
		o_dw_en = 1'b0;
		o_extend_operation = ZERO_EXT;
		o_srs_alu_b = 1'b0;
		o_jmp_en = 1'b0;
		o_beq_en = 1'b0;
		o_bne_en = 1'b0;

    o_wrong_instruction = 1'b0;
	
		casez(i_opcode)
			R_TYPE: begin
				o_dsrs_out = ALU_OUT;
        o_srs_alu_b = REG_PORT_B;
				o_rw_en = 1'b1;
        o_raddr_dst = RD;
			end
      ADDI: begin           //has ?, that why I use casez
				o_rw_en = 1'b1;
				o_extend_operation = SIGN_EXT;
				o_srs_alu_b = IMMEDIATE;
				o_dsrs_out = ALU_OUT;
			end
			SLTI: begin           //has ?, that why I use casez
				o_rw_en = 1'b1;
				o_extend_operation = SIGN_EXT;
				o_srs_alu_b = IMMEDIATE;
				o_dsrs_out = ALU_OUT;
			end
      I_TYPE: begin           //has ???, that why I use casez
				o_rw_en = 1'b1;
				o_extend_operation = ZERO_EXT;
				o_srs_alu_b = IMMEDIATE;
				o_dsrs_out = ALU_OUT;
			end
			JMP: o_jmp_en = 1'b1;
      BEQ: begin 
        o_beq_en = 1'b1;
        o_srs_alu_b = REG_PORT_B;
      end
			BNE:begin
        o_bne_en = 1'b1;
        o_srs_alu_b = REG_PORT_B;
      end
			LW: begin
				o_dsrs_out = MEM_DATA_OUT;
				o_rw_en = 1'b1;
				o_extend_operation = SIGN_EXT;
				o_srs_alu_b = IMMEDIATE;
			end
			SW: begin
				o_extend_operation = SIGN_EXT;
				o_srs_alu_b = IMMEDIATE;
				o_dw_en = 1'b1;
			end
      COPR: begin
        o_dsrs_out = COPR_OUT;
      end
      default: o_wrong_instruction = 1;
		endcase
	end

endmodule
