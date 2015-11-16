////////////////////////////////////////////////////////////
//Description: control for all mips depends opcode        //
////////////////////////////////////////////////////////////

`timescale 1ns/1ps

module mips_cu(i_opcode, i_function, i_copr_code, i_branch_code,
	o_raddr_dst, o_dsrs_out, o_rw_en,
	o_dw_en, o_dr_en, o_extend_operation, o_srs_alu_b, 
  o_jmp_en, o_beq_en, o_bne_en, o_sign_one, o_sign_zero, o_nozero, o_jregs_true,
	o_srs_rdout_a, o_srs_rb, o_dsel_width, 
	o_rfe_en, o_copr_we,
	o_sec_alu_en, o_sec_alu_op, o_sel_sec_alu,
  o_wrong_instruction);
	
	//Port declarations
	input  			[5 : 0] 						i_opcode;               //operation code
	input  			[5 : 0] 						i_function;
	input 			[4 : 0] 						i_copr_code;
	input 			[4 : 0] 						i_branch_code;
	output reg 				          		o_jmp_en;
	output reg 				           		o_rw_en;                //register write enable
	output reg	[1 : 0]	         		o_raddr_dst;            //register address distination
	output reg 				          		o_extend_operation;     
	output reg        	          	o_srs_alu_b;
	output reg 	[1 : 0]           	o_dsrs_out;             //data sourse out for memory access
	output reg 					          	o_dw_en;                //data write enable
	output reg 					          	o_dr_en;                //data read enable
	output reg           						o_beq_en;
  output reg 						          o_bne_en;
  output reg 						          o_nozero;								//bgtz
  output reg 						          o_sign_one;
  output reg 						          o_sign_zero;
	output reg 											o_jregs_true;
	
	output reg 											o_srs_rdout_a;
	output reg 											o_srs_rb;
	output reg 	[2 : 0] 						o_dsel_width;
   
	output reg 											o_rfe_en;
  output reg 											o_copr_we;

	output reg 											o_sec_alu_en;
	output reg [2 : 0]							o_sec_alu_op;
	output reg 											o_sel_sec_alu;
  
	output reg                      o_wrong_instruction;
	

	`include "local_params.v"
	`include "commands_param.v"
	//------------------------------------------------------
	
	always @* begin
		o_raddr_dst = RT;
		o_dsrs_out = 2'bx;
		o_rw_en = 1'b0;
		o_dw_en = 1'b0;
		o_dr_en = 1'b0;
		o_extend_operation = ZERO_EXT;
		o_srs_alu_b = 1'b0;
		o_jmp_en = 1'b0;
		o_beq_en = 1'b0;
		o_bne_en = 1'b0;
		o_nozero = 1'b0;
		o_sign_one = 1'b0;
		o_sign_zero = 1'b0;
		o_jregs_true = 1'b0;
		
		o_srs_rdout_a = REG_A;
		o_srs_rb	= RT_RB;
		o_dsel_width = WORD;
		
		o_copr_we = 1'b0;
		o_rfe_en = 1'b0;

		o_sec_alu_en = 1'b0;
		o_sec_alu_op = READ_HI;
		o_sel_sec_alu = ALU;

    o_wrong_instruction = 1'b0;
	
		case(i_opcode)
			R_TYPE: begin
				o_dsrs_out = ALU_OUT;
        o_srs_alu_b = REG_PORT_B;
				o_rw_en = 1'b1;
        o_raddr_dst = RD;
				
				case(i_function)
						JR: o_jregs_true = 1'b1;
					JALR: begin
						o_jregs_true = 1'b1;
					
						o_srs_rb = ZERO_RB;
						o_srs_rdout_a = INC_PC;
					end
					BREAK: o_rw_en = 1'b0;
					MULT, MULTU, DIV,DIVU, MTHI, MTLO: begin
						o_sec_alu_en = 1'b1;
						/*
							3'b001  --- mthi
							3'b011  --- mtlo
							3'b100  --- mult
							3'b101  --- multu
							3'b110  --- div
							3'b111  --- divu
					
						*/
						o_sec_alu_op = {i_function[3], i_function[1 : 0]};
						o_rw_en = 1'b0;
					end
					MFHI, MFLO: begin
						o_sec_alu_en = 1'b1;
						o_sel_sec_alu = SEC_ALU;
						/*
							3'b000   -- mfhi
							3'b010   -- mflo
						*/
						o_sec_alu_op = {i_function[3], i_function[1 : 0]};
					end
				endcase
			end
			BRANCHES: begin
				o_extend_operation = SIGN_EXT;
				case(i_branch_code)
					BGEZ, BGEZAL: o_sign_zero  = 1'b1;
					BLTZ, BLTZAL: o_sign_one = 1'b1;
				endcase
				case(i_branch_code)
					BGEZAL, BLTZAL: begin
						o_raddr_dst = R31;
						o_dsrs_out = ALU_OUT;
						o_srs_alu_b = REG_PORT_B;
						o_srs_rb = ZERO_RB;
						o_srs_rdout_a = INC_PC;
					end
				endcase
			end
      ADDI, ADDIU, SLTI, SLTIU: begin
				o_rw_en = 1'b1;
				o_extend_operation = SIGN_EXT;
				o_srs_alu_b = IMMEDIATE;
				o_dsrs_out = ALU_OUT;
			end
      ANDI, ORI, XORI, LUI: begin
				o_rw_en = 1'b1;
				o_extend_operation = ZERO_EXT;
				o_srs_alu_b = IMMEDIATE;
				o_dsrs_out = ALU_OUT;
			end
			JMP: o_jmp_en = 1'b1;
			JAL: begin
				o_jmp_en = 1'b1;
				
				o_rw_en = 1'b1;
				o_raddr_dst = R31;
				o_dsrs_out = ALU_OUT;
        o_srs_alu_b = REG_PORT_B;
				o_srs_rb = ZERO_RB;
				o_srs_rdout_a = INC_PC;
			end
      BEQ: begin 
        o_beq_en = 1'b1;
        o_srs_alu_b = REG_PORT_B;
				o_extend_operation = SIGN_EXT;
      end
			BNE: begin 
        o_bne_en = 1'b1;
        o_srs_alu_b = REG_PORT_B;
				o_extend_operation = SIGN_EXT;
      end
			BLEZ: begin
				o_extend_operation = SIGN_EXT;
				o_sign_one = 1'b1;
				o_srs_alu_b = REG_PORT_B;
				o_beq_en = 1'b1;
			end
			BGTZ: begin
				o_extend_operation = SIGN_EXT;
				o_sign_zero = 1'b1;
				o_srs_alu_b = REG_PORT_B;
				o_nozero = 1'b1;
			end
			LW, LB, LH, LBU, LHU, LWR, LWL: begin
				o_dsrs_out = MEM_DATA_OUT;
				o_rw_en = 1'b1;
				o_dr_en = 1'b1;
				o_srs_alu_b = IMMEDIATE;
				o_extend_operation = SIGN_EXT;
				/*
	 i_opcode[2 : 0]   dsel_width 	commands
						3'b000 -- BYTE  				-- LB
						3'b100 -- BYTE_UNS			-- LBU
						3'b001 -- HALFWORD 			-- LH
						3'b101 -- HALFWORD_UNS 	-- LHU
						3'b011 -- WORD 					-- LW
						3'b010 -- WORDLEFT  		-- LWL
						3'b110 -- WORDGIGHT 		-- LWR
					*/
				o_dsel_width = i_opcode[2 : 0];
			end
			SW, SH, SB, SWL, SWR: begin
				o_extend_operation = SIGN_EXT;
				o_srs_alu_b = IMMEDIATE;
				o_dw_en = 1'b1;
				/*
	 i_opcode[2 : 0]   dsel_width 	commands
						3'b000 -- BYTE  		-- SB
						3'b001 -- HALFWORD 	-- SH
						3'b011 -- WORD 			-- SW
						3'b010 -- WORDLEFT  -- SWL
						3'b110 -- WORDGIGHT -- SWR
					*/
				o_dsel_width = i_opcode[2 : 0];
			end
      COPR0: begin
			 	case(i_copr_code)
       	 MFC0:o_rw_en 	= 1'b1;
      	 MTC0:o_copr_we = 1'b1;
       	 RFE: o_rfe_en 	= 1'b1;
       	 default: o_wrong_instruction = 1'b1;
      	endcase
        o_dsrs_out = COPR_OUT;
      end
      default: o_wrong_instruction = 1'b1;
		endcase
	end

endmodule
