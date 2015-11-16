///////////////////////////////////////////////////
//Description: main module                       //
///////////////////////////////////////////////////

`timescale 1ns/1ps

module core(i_clk, i_arst_n, i_ext_int);
	parameter DATA_WIDTH        = 32;                  //data in all mips are 32bits
	parameter INSTR_ADDR_WIDTH  = 20;                 //2^26 program memory
	parameter INSTR_WIDTH       = 32;
	parameter DATA_ADDR_WIDTH   = 28;                    //2^28 bytes memory               
	parameter PC_WIDTH          = INSTR_ADDR_WIDTH - 2; //program counter
	parameter REG_ADDR_WIDTH    = 5;
	parameter ALU_CTRL_WIDTH    = 5;

	input i_clk;
	input i_arst_n;
  input i_ext_int;

	wire                          stall_en;        //if need buble in pipeline = 1 - when we have hazard

	wire [INSTR_WIDTH - 1 : 0]    instruction;     //next instrucion to decode stage
	wire [PC_WIDTH - 1 : 0]       pc_fe;           //for jmp
  wire [PC_WIDTH - 1 : 0]       pc_fe_de;        //for epc
	wire [PC_WIDTH - 1 : 0]       pc_jmp;          //new pc if jmp_en = 1
	wire                          jmp_en;          //

  //branch------------------------------------
  wire [PC_WIDTH - 1 : 0]       pc_branch;       //new pc if we have branch
  wire [PC_WIDTH - 1 : 0]       pc_branch_imm;   //for genereting branch address
  wire                          beq_en;
  wire                          bne_en;
  wire                          branch_en;
  wire [PC_WIDTH - 1 : 0]       pc_de;            //for branch
  //------------------------------------------

  wire [PC_WIDTH - 1 : 0]       pc_de_ex;         //for epc
  wire [PC_WIDTH - 1 : 0]       pc_ex_ma;
  wire [PC_WIDTH - 1 : 0]       pc_ma_wb;

	wire [DATA_WIDTH - 1 : 0]     rdout_a;          //register data out A
	wire [DATA_WIDTH - 1 : 0]     rdout_b;          //register data out B
	wire [DATA_WIDTH - 1 : 0]     immediate;
	wire [REG_ADDR_WIDTH - 1 : 0] sa;               //shift amount
	wire                          srs_alu_b;        //in execute for alu
	wire [ALU_CTRL_WIDTH - 1 : 0] alu_ctrl;
	wire [DATA_WIDTH - 1 : 0]     alu_res;          //alu result
	wire [DATA_WIDTH - 1 : 0]     rdout_b_ex;       //repeat rdout_b out of execute stage

	wire [DATA_WIDTH - 1 : 0]     dout_mem;         //out of memory stage
  
  //memory access stage write enable data in different stages
	wire                          dw_en_de;
	wire                          dw_en_ex;

  //memory access stage srs out in different stages
	wire  [1 : 0]                 dsrs_out_de;
	wire  [1 : 0]                 dsrs_out_ex;

  //register write enable in different stages
	wire                          rw_en_de;	
	wire                          rw_en_ex;
	wire                          rw_en_ma;

  //register address write in different stages
	wire [REG_ADDR_WIDTH - 1 : 0] raddr_w_de;	
	wire [REG_ADDR_WIDTH - 1 : 0] raddr_w_ex;
	wire [REG_ADDR_WIDTH - 1 : 0] raddr_w_ma;

  wire                          wr_addr_data;         //wrong address data in memory access stage
  wire                          ovf_flag;             //overflow from execute stage
  wire                          wr_instr_int;         //wrong instuction in decode stage
  wire                          int_catch;            //if detect interrupt or execution

  //kill stages if we have interrupt
  wire                          de_kill;
  wire                          ex_kill;
  wire                          ma_kill;

  //wires for coprocessor
  wire [DATA_WIDTH - 1 : 0] copr_dout;
  wire [REG_ADDR_WIDTH - 1 : 0] copr_addr;

  //eret in different stages
  wire                          eret_de;
  wire                          eret_ex;
  wire                          eret_ma;
  
  wire                          copr_w_en;
  wire [DATA_WIDTH -1 : 0]      epc;

  //valid means that command dont finished in that stage - needs for coprocessor
  //for example branch finesh in execute, lw - in memory access, addi - in write back
  //i dont need valid for fetch bacause of it is the first stage
  //also i dont need write back stage, becuse I never interrupt this stage.
  wire                          valid_ma;
  wire                          valid_ex;
  wire                          valid_de;


	fetch #(
		.INSTR_ADDR_WIDTH ( INSTR_ADDR_WIDTH 	))
	 u_fetch(
		.i_clk						( i_clk 				), 
		.i_arst_n 				( i_arst_n			), 
		.i_jmp_en 			  ( jmp_en			  ),
		.i_pc_jmp 				( pc_jmp 				), 

		.i_stall_en 			( stall_en 			),	
    .i_fe_kill        ( de_kill       ),

		.o_pc_fe 		    	( pc_fe		    	),
    .o_pc_fe_de       ( pc_fe_de      ), 
    .o_instruction 		( instruction 	));

	decode  #(
		.INSTR_ADDR_WIDTH	( INSTR_ADDR_WIDTH 	),
		.ALU_CTRL_WIDTH  	( ALU_CTRL_WIDTH 		))
	 u_decode(
		.i_clk						( i_clk 				), 
		.i_arst_n 				( i_arst_n			), 
		.i_instruction  	( instruction 	),
		.i_pc_fe 			    	( pc_fe	     		), 
  	.i_rw_en_wb 			( rw_en_ma 			), 
		.i_rdin 					( dout_mem 			),
    //chosing address for register write is doing in decode stage
    //so no need create module write back, as it has just wire
		.i_raddr_w_wb 		( raddr_w_ma 		),
    .i_raddr_w_ma     ( raddr_w_ex    ),


     
    //interrupts
    .i_de_kill        ( de_kill       ),
    .i_int_catch      ( int_catch     ),
    .i_epc_out        (epc),
    .o_wr_instr_int   ( wr_instr_int  ),
    .i_pc_fe_de       ( pc_fe_de      ),
    .o_valid_de       ( valid_de      ),

    .o_copr_addr      (copr_addr),
    .o_copr_en        (copr_w_en),
    .o_eret_de        (eret_de),

    .i_eret_ex        ( eret_ex       ),
    .i_eret_ma        ( eret_ma       ),
    //for branch------------------------
    .i_pc_branch      ( pc_branch     ),
    .i_branch_en      ( branch_en     ),
    .o_pc_de          ( pc_de         ),
    .o_pc_de_ex       ( pc_de_ex      ),
    .o_pc_branch_imm  ( pc_branch_imm ),
    .o_beq_en         ( beq_en        ),
    .o_bne_en         ( bne_en        ),
    //----------------------------------

		.o_stall_en 			( stall_en			), 

		.o_rdout_a 				( rdout_a 			), 
		.o_rdout_b 				( rdout_b 			), 
		.o_ext_immediate	( immediate 		), 
		.o_sa 						( sa 						), 
		.o_srs_alu_b 			( srs_alu_b 		), 
		.o_alu_ctrl 			( alu_ctrl 			),
		.o_dw_en_de 			( dw_en_de 			), 
		.o_dsrs_out_de		( dsrs_out_de 	),
		.o_pc_jmp 				( pc_jmp 				), 
		.o_jmp_en 			  ( jmp_en 		), 
		.o_raddr_w_de 		( raddr_w_de 		), 
		.o_rw_en_de 			( rw_en_de 			));

	execute #(
		.INSTR_ADDR_WIDTH	( INSTR_ADDR_WIDTH   ),
		.ALU_CTRL_WIDTH		( ALU_CTRL_WIDTH		 ))
	 u_execute(
		.i_clk						( i_clk 				), 
		.i_arst_n 				( i_arst_n			), 
		.i_alu_ctrl 			( alu_ctrl 			), 
		.i_data_a 				( rdout_a 			), 
		.i_data_b 				( rdout_b 			), 
		.i_immediate 			( immediate 		),
		.i_sa 						( sa 						), 
		.i_srs_b 					( srs_alu_b 		),
		.o_alu_result 		( alu_res 			), 
		.o_dout_b 				( rdout_b_ex 		),
    .o_ovf_flag       ( ovf_flag      ),

    //for branch------------------------
    .i_pc_branch_imm  ( pc_branch_imm ),
    .i_pc_de          ( pc_de         ),
    .i_beq_en         ( beq_en        ),
    .i_bne_en         ( bne_en        ),
    .o_pc_branch      ( pc_branch     ),
    .o_branch_en      ( branch_en     ),
    //----------------------------------	

		.i_dw_en_de 			( dw_en_de 			), 
		.i_dsrs_out_de		( dsrs_out_de		), 
		.i_rw_en_de				( rw_en_de 			), 
		.i_raddr_w_de			( raddr_w_de 		),
    .i_eret_de        ( eret_de       ),
		.o_dw_en_ex				( dw_en_ex 			), 
		.o_dsrs_out_ex 		( dsrs_out_ex 	), 
		.o_rw_en_ex 			( rw_en_ex 			), 
		.o_raddr_w_ex 		( raddr_w_ex		),
    .o_eret_ex        ( eret_ex       ),

    .i_pc_de_ex       ( pc_de_ex      ),
    .o_pc_ex_ma       ( pc_ex_ma      ),
    .i_ex_kill        ( ex_kill       ),
    .o_valid_ex       ( valid_ex      ));

	mem_access #(
		.DATA_ADDR_WIDTH	( DATA_ADDR_WIDTH		 ),
    .PC_WIDTH         ( PC_WIDTH           ))
	 u_mem_access(
		.i_clk						( i_clk 				), 
		.i_arst_n 				( i_arst_n			), 
		.i_dw_en 					( dw_en_ex 			),
		.i_daddr 					( alu_res 			), 
		.i_din 						( rdout_b_ex 		), 
    .i_copr_dout      ( copr_dout     ), 
		.i_dsrs_out 			( dsrs_out_ex 	), 
		.o_dout 					( dout_mem 			),

		.i_rw_en_ex 			( rw_en_ex 			),
		.i_raddr_w_ex			( raddr_w_ex 		),
    .i_eret_ex        ( eret_ex       ),
		.o_rw_en_ma 			( rw_en_ma 			),
		.o_raddr_w_ma			( raddr_w_ma 		),
    .o_eret_ma        ( eret_ma       ),

    .o_valid_ma       ( valid_ma      ),
    .o_wr_addr_data   ( wr_addr_data  ),
    .i_ma_kill        ( ma_kill       ));

   coprocessor #( 
    .PC_WIDTH         ( PC_WIDTH           ))
    u_coprocessor(
    .i_clk            ( i_clk         ), 
    .i_arst_n         ( i_arst_n      ), 
    .i_en             ( copr_w_en     ), 
    .i_address        ( copr_addr     ), 
    .i_din            ( rdout_b       ), 
    .i_eret           ( eret_ma       ), 
                    
    .i_external_int   ( i_ext_int     ), 
    .i_ovf_int        ( ovf_flag      ), 
    .i_wr_instr_int   ( wr_instr_int  ),
    .i_wr_addr_data   ( wr_addr_data  ),
                    
    .i_pc_fe          ( pc_fe         ),               
    .i_pc_fe_de       ( pc_fe_de       ),
    .i_pc_de_ex       ( pc_de_ex       ),    
    .i_pc_ex_ma       ( pc_ex_ma       ), 

    .i_valid_ma       ( valid_ma      ),
    .i_valid_ex       ( valid_ex      ),
    .i_valid_de       ( valid_de      ),
                    
    .o_dout           ( copr_dout     ), 
    .o_epc            ( epc           ),
    .o_ma_kill        ( ma_kill       ), 
    .o_ex_kill        ( ex_kill       ), 
    .o_de_kill        ( de_kill       ), 
    .o_int_true       ( int_catch     ));

endmodule
