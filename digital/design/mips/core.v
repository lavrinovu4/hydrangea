///////////////////////////////////////////////////
//Description: main module                       //
///////////////////////////////////////////////////

`timescale 1ns/1ps

module core(i_clk, i_arst_n, i_core_en, i_int_source,
					
						o_wb_cyc, o_wb_stb, o_wb_sel, o_wb_we, o_wb_adr, o_wb_dat,
						i_wb_dat, i_wb_ack	);

  parameter PC_START_ADDRRES  = 0;
	parameter DATA_WIDTH        = 32;                  //data in all mips are 32bits
	parameter INSTR_ADDR_WIDTH  = 32;                 //2^26 program memory
	parameter INSTR_WIDTH       = 32;
	parameter PC_WIDTH          = INSTR_ADDR_WIDTH - 2; //program counter
	parameter REG_ADDR_WIDTH    = 5;

	parameter N_INTS 						= 9;

	//-----------------------------------
	input 									i_clk;
	input 									i_arst_n;
  input                   i_core_en;

  input [N_INTS - 1 : 0] 	i_int_source;

	//wishbone-------------------
	input	 							i_wb_ack;
	input [31 : 0] 			i_wb_dat;
	output 							o_wb_cyc;
	output 							o_wb_stb;
	output 							o_wb_we;
	output [3 : 0] 			o_wb_sel;
	output [31 : 0] 		o_wb_adr;
	output [31 : 0] 		o_wb_dat;


	//-------------------------------------------------------------------------------------------

	wire                          stall_en;        //if need buble in pipeline = 1 - when we have hazard

	wire [INSTR_WIDTH - 1 : 0]    instruction;     //next instrucion to decode stage
  wire [PC_WIDTH - 1 : 0]       pc_fe;        //for epc
  wire [PC_WIDTH - 1 : 0]       inc_pc;        	 //for jal/jalr
	wire [PC_WIDTH - 1 : 0]       pc_jmp;          //new pc if jmp_en = 1
	wire                          jmp_en;          //

  //branch------------------------------------
	wire                          beq_en;
  wire                          bne_en;
  wire                          sign_bit;
  wire                          nozero;
  wire                          branch_en;
	wire 	[INSTR_ADDR_WIDTH -1  : 0] pc_branch;
  //------------------------------------------

  wire [PC_WIDTH - 1 : 0]       pc_de;         //for epc
  wire [PC_WIDTH - 1 : 0]       pc_ex;

	wire [DATA_WIDTH - 1 : 0]     rdout_a;          //register data out A
	wire [DATA_WIDTH - 1 : 0]     rdout_b;          //register data out B
	wire [DATA_WIDTH - 1 : 0]     immediate;
	wire [REG_ADDR_WIDTH - 1 : 0] sa;               //shift amount
	wire                          srs_alu_b;        //in execute for alu
	wire [5 : 0] 									alu_ctrl;
	wire [DATA_WIDTH - 1 : 0]     alu_res;          //alu result
	wire [DATA_WIDTH - 1 : 0]     rdout_b_ex;       //repeat rdout_b out of execute stage

	wire [DATA_WIDTH - 1 : 0]     dout_mem;         //out of memory stage
  
  //memory access stage write enable data in different stages
	wire                          dw_en_de;
	wire                          dw_en_ex;
 
  //memory access stage read enable data in different stages
	wire                          dr_en_de;
	wire                          dr_en_ex;

  //memory access stage srs out in different stages
	wire  [1 : 0]                 dsrs_out_de;
	wire  [1 : 0]                 dsrs_out_ex;

  //memory acces select byte, halfword or word
  wire  [2 : 0]                 dsel_width_de;
  wire  [2 : 0]                 dsel_width_ex;


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
  wire                          div_zero;             //execute stage
  wire                          wr_instr;         //wrong instuction in decode stage
  wire                          wr_adr_instr;         //wrong adrress instuction in decode stage

	wire 	[4 : 0] 								exceptions;
	wire 													delay_slot;				//commands which is in epc, was in delay slot

  wire                          ie_catch;            //if detect interrupt or execution
  wire                          int_only; 					 //interrupts only

  //wires for coprocessor
  wire [DATA_WIDTH - 1 : 0] copr_dout;
  wire [REG_ADDR_WIDTH - 1 : 0] copr_addr;

  //eret in different stages
  wire                          rfe_en;
  
  wire                          copr_wen;

	wire 													stall_en_ex;
	wire 													sec_alu_en;
	wire [2 : 0]									sec_alu_op;
	wire 													sel_sec_alu;

	wire 													stall_en_ma;
	wire 													mem_data_we;
	wire 													mem_data_re;
	wire [3 : 0]									mem_data_sel;
	wire [29 : 0]									mem_data_adr;
	wire [31 : 0]									mem_data_din;
	wire [31 : 0]									mem_data_dout;
	wire 													mem_data_ack;


  wire [31 : 0]           mem_instr_din;
  wire [29 : 0]           mem_instr_adr;
  wire                    mem_instr_ack;
  wire                    mem_instr_req;

  wire                    stall_en_fe;


	assign exceptions = {div_zero, ovf_flag, wr_addr_data, wr_adr_instr, wr_instr};

	assign mem_instr_adr = pc_fe;

	fetch #(
		.INSTR_ADDR_WIDTH ( INSTR_ADDR_WIDTH 	),
    .PC_START_ADDRRES ( PC_START_ADDRRES  ))
	 u_fetch(
		.i_clk						( i_clk 				), 
		.i_arst_n 				( i_arst_n			), 
    .i_core_en        ( i_core_en     ), 
		.i_jmp_en 			  ( jmp_en			  ),
		.i_pc_jmp 				( pc_jmp 				),
	
		.i_instr_mem 			( mem_instr_din 	),
    .i_read_ack       ( mem_instr_ack   ),
    .o_read_req       ( mem_instr_req   ),
    .o_stall_en_fe    ( stall_en_fe     ),

		.i_ie_catch 			( ie_catch 			),
		.i_stall_en_de 		( stall_en 			),	
		.i_stall_en_ex 		( stall_en_ex	  ),	
		.i_stall_en_ma 		( stall_en_ma 	),	
		
		.o_inc_pc 		    ( inc_pc	    	),
    .o_pc_fe		      ( pc_fe      		), 
    .o_instruction 		( instruction 	));

	decode  #(
		.INSTR_ADDR_WIDTH	( INSTR_ADDR_WIDTH 	))
	 u_decode(
		.i_clk						( i_clk 				), 
		.i_arst_n 				( i_arst_n			), 
		.i_instruction  	( instruction 	),
  	.i_rw_en_wb 			( rw_en_ma 			), 
		.i_rdin 					( dout_mem 			),
    //choosing address for register write is doing in decode stage
    //so no need create module write back, as it has just wire
		.i_raddr_w_wb 		( raddr_w_ma 		),
    .i_raddr_w_ma     ( raddr_w_ex    ),
    .i_rw_en_ex       ( rw_en_ex      ),

     
    //interrupts
    .i_ie_catch      	( ie_catch     ),
    .o_wr_instr			  ( wr_instr 			),
    .o_wr_adr_instr		( wr_adr_instr	),
    .i_pc_fe       		( pc_fe      		),

    .o_copr_addr      ( copr_addr			),
    .o_copr_wen       ( copr_wen			),
    .o_rfe_en        	( rfe_en				),
		
    //for branch------------------------
    .i_branch_en      ( branch_en     ),
		.i_pc_branch 			( pc_branch 		),
    .o_beq_en         ( beq_en        ),
    .o_bne_en         ( bne_en        ),
    .o_nozero         ( nozero        ),
    .o_sign_bit       ( sign_bit      ),
    //----------------------------------

    .o_pc_de       		( pc_de      		),
		.o_stall_en 			( stall_en			), 

		.o_rdout_a 				( rdout_a 			), 
		.o_rdout_b 				( rdout_b 			), 
		.o_ext_immediate	( immediate 		), 
		.o_sa 						( sa 						), 
		.o_srs_alu_b 			( srs_alu_b 		), 
		.o_alu_ctrl 			( alu_ctrl 			),
		.o_dw_en_de 			( dw_en_de 			), 
		.o_dr_en_de 			( dr_en_de 			), 
		.o_dsrs_out_de		( dsrs_out_de 	), 
    .o_dsel_width_de  ( dsel_width_de ),
		.o_pc_jmp 				( pc_jmp 				), 
		.o_jmp_en 			  ( jmp_en 				), 
		.o_raddr_w_de 		( raddr_w_de 		), 
		.o_rw_en_de 			( rw_en_de 			),
		
		.i_inc_pc 		    ( inc_pc	    	),

		.o_sec_alu_en			( sec_alu_en 		),
		.o_sec_alu_op			(	sec_alu_op		),
		.o_sel_sec_alu		( sel_sec_alu 	),
		.i_stall_en				( stall_en_ex | stall_en_ma | stall_en_fe	));

	execute #(
		.INSTR_ADDR_WIDTH	( INSTR_ADDR_WIDTH   ))
	 u_execute(
		.i_clk						( i_clk 				), 
		.i_arst_n 				( i_arst_n			),
		.i_stall_en 			( stall_en_ma	 | stall_en_fe	), 
		.i_alu_ctrl 			( alu_ctrl 			), 
		.i_data_a 				( rdout_a 			), 
		.i_data_b 				( rdout_b 			), 
		.i_immediate 			( immediate 		),
		.i_sa 						( sa 						), 
		.i_srs_b 					( srs_alu_b 		),
		.o_alu_result 		( alu_res 			), 
		.o_dout_b 				( rdout_b_ex 		),

    //for branch------------------------
    .i_beq_en         ( beq_en        ),
    .i_bne_en         ( bne_en        ),
    .i_sign_bit       ( sign_bit      ),
    .i_nozero       	( nozero      ),
		.o_pc_branch 			( pc_branch 		),
    .o_branch_en      ( branch_en     ),
    //----------------------------------	

		.i_dw_en_de 			( dw_en_de 			), 
		.i_dr_en_de 			( dr_en_de 			), 
		.i_dsrs_out_de		( dsrs_out_de		), 
    .i_dsel_width_de  ( dsel_width_de ),
		.i_rw_en_de				( rw_en_de 			), 
		.i_raddr_w_de			( raddr_w_de 		),
		.o_dw_en_ex				( dw_en_ex 			), 
		.o_dr_en_ex				( dr_en_ex 			), 
		.o_dsrs_out_ex 		( dsrs_out_ex 	), 
    .o_dsel_width_ex  ( dsel_width_ex ),
		.o_rw_en_ex 			( rw_en_ex 			), 
		.o_raddr_w_ex 		( raddr_w_ex		),

    .i_pc_de       		( pc_de      		),
    .o_pc_ex       		( pc_ex      		),

		.i_sec_alu_en 		( sec_alu_en 		),
		.i_sec_alu_op 		(	sec_alu_op 		),
		.i_sel_sec_alu 		(	sel_sec_alu 	),

		.i_int_only 			( int_only 			),
		.o_delay_slot 		( delay_slot 		),

		.o_div_zero 			(	div_zero 			),
    .o_ovf_flag       ( ovf_flag      ),
    .o_wr_addr_data   ( wr_addr_data  ),

		.o_stall_en_ex		(	stall_en_ex	));

	mem_access #(
    .PC_WIDTH         ( PC_WIDTH           ))
	 u_mem_access(
		.i_clk						( i_clk 				), 
		.i_arst_n 				( i_arst_n			), 
		.i_dw_en 					( dw_en_ex 			),
		.i_dr_en 					( dr_en_ex 			),
		.i_daddr 					( alu_res 			), 
		.i_din 						( rdout_b_ex 		), 
    .i_copr_dout      ( copr_dout     ), 
		.i_dsrs_out 			( dsrs_out_ex 	),
    .i_dsel_width     ( dsel_width_ex ),
		.o_dout 					( dout_mem 			),

		.i_rw_en_ex 			( rw_en_ex 			),
		.i_raddr_w_ex			( raddr_w_ex 		),
		.o_rw_en_ma 			( rw_en_ma 			),
		.o_raddr_w_ma			( raddr_w_ma 		),

		.o_stall_en_ma 		( stall_en_ma 	),

		.o_adr						( mem_data_adr	),
		.o_sel						( mem_data_sel	),
		.o_we							( mem_data_we 	),
		.o_re							( mem_data_re		),
		.o_din						( mem_data_din 	),
		.i_dout						( mem_data_dout ),
		.i_ack						( mem_data_ack 	));
	

   coprocessor #( 
    .N_INTS         ( N_INTS           ))
    u_coprocessor(
    .i_clk            ( i_clk         ), 
    .i_arst_n         ( i_arst_n      ), 
    .i_en             ( copr_wen    	), 
    .i_address        ( copr_addr     ), 
    .i_din            ( rdout_b       ), 
    
		.i_rfe_en         ( rfe_en       	),
		
		.i_interrupts 		( i_int_source	),
		.i_delay_slot 		( delay_slot 		),
		.i_exceptions 		( exceptions 		),
                    
    .i_pc		       		( pc_ex       	),    
                    
    .o_dout           ( copr_dout     ), 
    .o_ie_catch 	    ( ie_catch     	),
    .o_int_only       ( int_only     	));


   wishbone u_wishbone(
    .o_wb_cyc         ( o_wb_cyc      ), 
    .o_wb_stb         ( o_wb_stb      ), 
    .o_wb_sel         ( o_wb_sel      ), 
    .o_wb_we          ( o_wb_we       ), 
    .o_wb_adr         ( o_wb_adr      ), 
    .o_wb_dat         ( o_wb_dat      ),
    .i_wb_dat         ( i_wb_dat      ), 
    .i_wb_ack         ( i_wb_ack      ),
                
    .i_clk            ( i_clk     ),
    .i_rb             ( i_arst_n  ),
    
    .i_address_mem1   ( mem_instr_adr ),
    .i_req_mem1       ( mem_instr_req ),
    .o_data_mem1      ( mem_instr_din ),
    .o_ack_mem1       ( mem_instr_ack ),

    .i_address_mem2   ( mem_data_adr              ),
    .i_req_mem2       ( mem_data_we | mem_data_re ),
    .i_sel_mem2       ( mem_data_sel              ),
    .o_data_mem2      ( mem_data_dout             ),
    .i_wr_mem2        ( mem_data_we               ),
    .i_data_mem2      ( mem_data_din              ),
    .o_ack_mem2       ( mem_data_ack              ));

endmodule
