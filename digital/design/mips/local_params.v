//alu_op
localparam SHIFT_CONSTANT_OUT = 4'h0,
					SHIFT_OUT      	    = 4'h1,
        	LUI_OUT	        		= 4'h3,
					ADDER_OUT       		= 4'h8,
	        LOGIK_OUT 	      	= 4'h9,
					SLT_OUT 	        	= 4'ha;

//decode op_sel in alu-----------------
localparam  SLT 	= 2'h2,
        		SLTU 	= 2'h3;

localparam	ADD 	= 2'h0,
        		ADDU 	= 2'h1,
        		SUB 	= 2'h2,
        		SUBU 	= 2'h3;

localparam 	AND 	= 2'h0,
        		OR  	= 2'h1,
	        	XOR 	= 2'h2,
	        	NOR 	= 2'h3;

localparam 	SLL 	= 2'h0,
        		ROR 	= 2'h1,
	        	SRL 	= 2'h2,
	        	SRA 	= 2'h3;

//extendent operation----------------
localparam  ZERO_EXT      = 1'b0,
            SIGN_EXT      = 1'b1;
	
//srs_alu_b--------------------------
localparam 	REG_PORT_B = 0,
            IMMEDIATE = 1;

//output from register file or pc+1(for j and link)
localparam 	REG_A 				= 1'b0,
						INC_PC 				= 1'b1;

//srs register B---------------------
localparam 	RT_RB 				= 1'b0,
						ZERO_RB				= 1'b1;
																																
//decode o_dsrs_out------------------
localparam  ALU_OUT       = 2'b00,
            MEM_DATA_OUT  = 2'b01,
            COPR_OUT      = 2'b10;

//srs register A---------------------																
localparam  RT    = 2'b00,
            RD    = 2'b01,
            R31   = 2'b10;

//dsel_width-------------------------
localparam BYTE 				= 3'b000,
					 BYTE_UNS 		= 3'b100,
					 HALFWORD 		= 3'b001,
					 HALFWORD_UNS = 3'b101,
					 WORD 				= 3'b011,
					 WORDLEFT 		= 3'b010,
					 WORDRIGHT		= 3'b110;

//sel_sec_alu------------------------
localparam 	ALU = 1'b0,
						SEC_ALU = 1'b1;

//sec_alu_op------------------------
localparam READ_HI = 3'b000;
