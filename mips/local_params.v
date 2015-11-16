//alu_op
localparam 	SHIFT_OUT      	    = 3'h0,
	        SLT_OUT 	        = 3'h1,
	        ADDER_OUT       	= 3'h2,
	        LOGIK_OUT 	      	= 3'h3,
	        SHIFT_CONSTANT_OUT 	= 3'h4,
        	LUI_OUT	        	= 3'h5;

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
//------------------------------------

//decode opcode
localparam 	R_TYPE 	= 6'b00_0000,
	        JMP   	= 6'b00_0010,
	        BEQ   	= 6'b00_0100,
	        BNE   	= 6'b00_0101,
            ADDI    = 6'b00_100?,
        	SLTI  	= 6'b00_101?,
            LUI   	= 6'b00_1111,
        	LOGIC_I	= 6'b00_11??,
            I_TYPE  = 6'b00_1???,
        	LW    	= 6'b10_0011,
	        SW     	= 6'b10_1011,
            COPR    = 6'b01_0000;


//decode function
localparam JR = 6'b001000;


localparam  MFC0 = 5'b00000,
            MTC0 = 5'b00100,
            RFE  = 5'b10000;