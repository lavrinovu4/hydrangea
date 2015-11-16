//decode opcode
localparam 	R_TYPE 	= 6'b00_0000,
					BRANCHES 	= 6'b00_0001,
	        JMP   	= 6'b00_0010,
	        JAL   	= 6'b00_0011,
	        BEQ   	= 6'b00_0100,
	        BNE   	= 6'b00_0101,
	        BLEZ   	= 6'b00_0110,
	        BGTZ  	= 6'b00_0111,
            ADDI    = 6'b00_1000,
            ADDIU    = 6'b00_1001,
        		SLTI  	= 6'b00_1010,
        		SLTIU  	= 6'b00_1011,
						ANDI 		= 6'b00_1100,
						ORI 		= 6'b00_1101,
						XORI 		= 6'b00_1110,
            LUI   	= 6'b00_1111,
          LB      = 6'b10_0000,
          LH      = 6'b10_0001,
        	LW    	= 6'b10_0011,
          LBU     = 6'b10_0100,
          LHU     = 6'b10_0101,
					LWL 		= 6'b10_0010,
					LWR 		= 6'b10_0110,
          SB      = 6'b10_1000,
          SH      = 6'b10_1001,
	        SW     	= 6'b10_1011,
					SWL 		= 6'b10_1010,
					SWR 		= 6'b10_1110,
          COPR0   = 6'b01_0000;


//decode function
localparam JR = 6'b001000,
				 JALR = 6'b001001,
				 BREAK= 6'b001101,

					MFHI = 6'b010000,
					MTHI = 6'b010001,
					MFLO = 6'b010010,
					MTLO = 6'b010011,
					MULT = 6'b011000,
					MULTU = 6'b011001,
					DIV 	= 6'b011010,
					DIVU 	= 6'b011011;

//decode coprocessor0
localparam  MFC0 = 5'b00000,
            MTC0 = 5'b00100,
            RFE  = 5'b10000;

localparam 	BGEZ 		= 5'b00001,
					 	BGEZAL	= 5'b10001,
						BLTZ 		= 5'b00000,
						BLTZAL 	= 5'b10000;
