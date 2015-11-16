//////////////////////////////////////////////////////////////////////////////////////////////////
//Description:decode stage																																			//
//////////////////////////////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ps

module decode(i_clk, i_arst_n, i_instruction, i_pc_fe, i_rw_en_wb, i_rdin, 
			i_raddr_w_wb, i_raddr_w_ma, i_rw_en_ex,
     	i_branch_en, i_pc_branch, o_stall_en,
      i_ie_catch,
      o_copr_addr, o_copr_wen, o_rfe_en, 
			o_rdout_a, o_rdout_b, o_ext_immediate, o_sa, o_srs_alu_b, o_alu_ctrl, 
      o_pc_de, o_beq_en, o_bne_en, o_sign_bit, o_nozero,
			o_dw_en_de, o_dr_en_de, o_dsrs_out_de, o_dsel_width_de, 
			o_pc_jmp, o_jmp_en, o_raddr_w_de, o_rw_en_de,
      o_wr_instr, o_wr_adr_instr,
			i_inc_pc, 
			o_sec_alu_en, o_sec_alu_op, o_sel_sec_alu,
			i_stall_en);

	parameter DATA_WIDTH 	    	        = 32;                     //data memory
	parameter INSTR_ADDR_WIDTH 	        = 32;                     //2^30 program memory
	parameter INSTR_WIDTH 		          = 32;
	parameter PC_WIDTH 		              = INSTR_ADDR_WIDTH - 2;
	parameter JMP_IMM_WIDTH 	          = PC_WIDTH - 4;           //for generating jmp
	parameter IMM_WIDTH 		            = 16;                     //for generating data to alu port b
	parameter EXT_IM_WIDTH 							= INSTR_ADDR_WIDTH - IMM_WIDTH;
	parameter REG_ADDR_WIDTH 		        = 5;                      //general purpose register
  parameter ADDR_TRANSITION_INTERRUPT = 'h2;                    //*4 = addres when interrupt happened 

	`include "func.v"                                     ///for log();
	localparam ADDR_DATA_WIDTH = log(2, DATA_WIDTH);
	
	//Port declaration
	input                                 i_clk;
	input                                 i_arst_n;
	input      [INSTR_WIDTH - 1 : 0]      i_instruction;
  input      [PC_WIDTH - 1 : 0]         i_pc_fe;     //epc, jmp, branch
	input                                 i_rw_en_wb;     //rigester write enable from write back stage
	input      [DATA_WIDTH - 1 : 0]       i_rdin;         //data from write back stage

	input 																i_stall_en;			//from execute

	input 																i_rw_en_ex; 		//for hazard checking
	input      [REG_ADDR_WIDTH - 1 : 0]   i_raddr_w_wb;   //register addres write from write back stage
	input      [REG_ADDR_WIDTH - 1 : 0]   i_raddr_w_ma;   //from memory access stage
  input                                 i_branch_en;
  input                                 i_ie_catch;    //interrupt happened = 1
 

	input 		 [PC_WIDTH - 1 : 0]					i_inc_pc;				//for jal/lalr
	input 		 [31 : 0] 									i_pc_branch;
  output reg                            o_beq_en;       //branch if equal enable
  output reg                            o_bne_en;       //branch if not equal enable
  output reg                            o_sign_bit;     //branch if 1
  output reg                            o_nozero;     	//bgtz
  output reg [PC_WIDTH - 1 : 0]         o_pc_de;      	//for epc, repeat i_pc_fe
  output reg [DATA_WIDTH - 1 : 0]       o_rdout_a;        //register data out port a
	output reg [DATA_WIDTH - 1 : 0]       o_rdout_b;        //register data out port b
	output reg [DATA_WIDTH - 1 : 0]       o_ext_immediate;  //data after extender
	output reg [ADDR_DATA_WIDTH - 1 : 0]  o_sa;             //shift amount
	output reg                            o_srs_alu_b;
	output reg [5 : 0]   									o_alu_ctrl; 
	output reg [PC_WIDTH - 1 : 0]         o_pc_jmp;          //new program counter if we have j, branch, int, jr
	output                                o_jmp_en;          //jump enable
	output reg [REG_ADDR_WIDTH - 1 : 0]   o_raddr_w_de;      //register address write from decode stage - control signals for next stages
	output reg                            o_rw_en_de;
	output reg                            o_dw_en_de;
	output reg                            o_dr_en_de;
	output reg [1 : 0]                    o_dsrs_out_de;
	output reg [2 : 0]                    o_dsel_width_de;

  output reg [REG_ADDR_WIDTH - 1 : 0]   o_copr_addr;
  output reg                            o_copr_wen;
  output reg                            o_rfe_en;

	output                                o_stall_en;     //load "nop" if "1"
  output reg                            o_wr_instr;
  output reg                            o_wr_adr_instr;

	output reg 														o_sec_alu_en;
	output reg [2 : 0]										o_sec_alu_op;
	output reg 														o_sel_sec_alu;
	
	//-----------------------------------------Internal variables--------------------------------
	wire [5 : 0]     								opcode;       //operation code from instruction
	wire [REG_ADDR_WIDTH - 1 : 0]   rs;           //read register source address
	wire [REG_ADDR_WIDTH - 1 : 0]   rt;	          //read register second sourse address

  wire [REG_ADDR_WIDTH - 1 : 0] 	rd;                  //register destination address
	wire [ADDR_DATA_WIDTH - 1 : 0] 	sa_nxt;                  //shift amount
	wire [5 : 0] 										alu_func;

	wire [IMM_WIDTH - 1 : 0] 	      immediate;
	wire [JMP_IMM_WIDTH - 1 : 0] 	  imm_jmp;
  wire [PC_WIDTH - 1 : 0]         pc_jmp_nxt;
  wire                            jmp_en_nxt;

	wire [DATA_WIDTH - 1 : 0]       rdout_a_nxt;             //regiter data out port a
	wire [DATA_WIDTH - 1 : 0] 			rdout_a_comb; 					 //reg out A or pc + 1(for j and link) 
	wire [DATA_WIDTH - 1 : 0]       rdout_b_nxt;             //regiter data out port a 
	wire [DATA_WIDTH - 1 : 0]       ext_immediate_nxt;
	wire                            srs_alu_b_nxt;
	wire                            extend_operation;
	wire [5 : 0]   									alu_ctrl_nxt;
	wire [1 : 0]                    dsrs_out_nxt;
	wire [1 : 0]                    raddr_dst;               //register addres destination rt or rd
  reg  [REG_ADDR_WIDTH - 1 : 0]   raddr_w_de_nxt;
	wire                            rw_en_nxt;
	wire                            beq_en_nxt;
	wire                            bne_en_nxt;
	wire                            dw_en_nxt;                    //data write enable
	wire                            dr_en_nxt;                    //data read enable
	wire [2 : 0] 										dsel_width_nxt;

	wire                            wrong_instr_alu_cu;
  wire                            wrong_instr_mipc_cu;

	wire 														rfe_en_nxt;
  wire                            kill_decode;
  wire                            copr_wen_nxt;

	wire                            jregs_true;
  wire                            jregs_en;
	
	wire 														srs_rb;
	wire [REG_ADDR_WIDTH - 1 : 0]		addr_rb_nxt;
	wire 														srs_rdout_a;

	wire														sign_bit_nxt; 					//for branches(bqez, bltz)
	wire														nozero_nxt; 					//for bgtz
	wire 														sign_one;
	wire 														sign_zero;

	wire 														sec_alu_en_nxt;
	wire [2 : 0]										sec_alu_op_nxt;
	wire 														sel_sec_alu_nxt;
	
	wire 														wr_instr_nxt;
	wire 														wr_adr_instr_nxt;
	
  `include "local_params.v"
	//------------------------------------------------------------------------------------------
	assign {opcode, rs, rt, rd, sa_nxt, alu_func} = i_instruction;
	assign immediate = i_instruction[IMM_WIDTH - 1 : 0];
	assign imm_jmp = i_instruction[JMP_IMM_WIDTH - 1 : 0];

	assign pc_jmp_nxt = {i_pc_fe[PC_WIDTH - 1 : JMP_IMM_WIDTH], imm_jmp};

	assign jregs_en = jregs_true & ~o_stall_en;
	assign o_jmp_en = jmp_en_nxt | i_branch_en | i_ie_catch | jregs_en;

  assign wr_instr_nxt = wrong_instr_mipc_cu | wrong_instr_alu_cu;
	assign wr_adr_instr_nxt = |rdout_a_nxt[1 : 0] & jregs_en;

	assign en_decode = ~i_stall_en;
  assign kill_decode = en_decode &(o_stall_en | i_ie_catch | o_wr_instr | o_wr_adr_instr);

  //-------------------------------------------------------------------------------------------

	assign addr_rb_nxt = srs_rb == ZERO_RB ? 5'h0 : rt;
	
  //general purpose registers
	register_file u_register_file(
		.i_clk							( i_clk 					  	),
		.i_addr_ra					( rs 	  					  	),
		.i_addr_rb					( addr_rb_nxt  				),
		.i_w_en 						( i_rw_en_wb 			  	),
		.i_addr_w 					( i_raddr_w_wb		  	),
		.i_din    					( i_rdin 					  	),
		.o_dout_ra 					( rdout_a_nxt 		  	),
		.o_dout_rb 					( rdout_b_nxt 		  	));

	assign ext_immediate_nxt = {{EXT_IM_WIDTH{(extend_operation == SIGN_EXT) & immediate[15]}},
														  immediate};
	
	alu_cu u_alu_cu(
		.i_function					( alu_func 						),
		.i_opcode						( opcode 	  					),
		.o_alu_ctrl					( alu_ctrl_nxt 				),
		.o_wrong_instr		 	( wrong_instr_alu_cu	));               

	mips_cu u_mips_cu(
		.i_opcode 					( opcode   				  	),
		.i_function					( alu_func 						),
		.i_copr_code      	( rs            			),
		.i_branch_code      ( rt            			),
		.o_raddr_dst				( raddr_dst				  	),
		.o_dsrs_out 				( dsrs_out_nxt		  	),
		.o_rw_en						( rw_en_nxt 			  	),
		.o_dw_en 						( dw_en_nxt 					),
		.o_dr_en 						( dr_en_nxt 					),
		.o_extend_operation ( extend_operation 	  ),
		.o_srs_alu_b 				( srs_alu_b_nxt 		  ),
		.o_jmp_en 					( jmp_en_nxt 	 			  ),
		.o_beq_en 			    ( beq_en_nxt 	        ),
		.o_bne_en 			    ( bne_en_nxt 	        ),
		.o_nozero 			    ( nozero_nxt	        ),
		.o_sign_one 			    ( sign_one 	        ),
		.o_sign_zero 			    ( sign_zero	        ),
		.o_srs_rdout_a	    ( srs_rdout_a	        ),
		.o_srs_rb 			    ( srs_rb		 	        ),
		.o_dsel_width 			( dsel_width_nxt			),
		.o_jregs_true		    ( jregs_true 	        ),
		.o_rfe_en         	( rfe_en_nxt   	),
    .o_copr_we        	( copr_wen_nxt   ),

		.o_sec_alu_en 		( sec_alu_en_nxt 	),
		.o_sec_alu_op 		( sec_alu_op_nxt 	),
		.o_sel_sec_alu 		( sel_sec_alu_nxt ),

    .o_wrong_instruction( wrong_instr_mipc_cu ));
 
 	hazard_cu u_hazard_cu(
		.i_opcode 				( opcode 				),
    .i_branch_en      ( i_branch_en   ),
		.i_rs 						( rs 						), 
		.i_rt 						( rt 						), 
		.i_ws_ex					( o_raddr_w_de	), 
		.i_ws_ma					( i_raddr_w_ma	), 
		.i_ws_wb					( i_raddr_w_wb	),
		.i_wen_ex 				( o_rw_en_de 		),
		.i_wen_ma 				( i_rw_en_ex 		),
		.i_wen_wb 				( i_rw_en_wb 		),
		.o_stall_en 			( o_stall_en 		));

  //generate new program counter if we have one of types of jmp
  always @* begin
    if(i_ie_catch)
        o_pc_jmp = ADDR_TRANSITION_INTERRUPT;
    else begin
      o_pc_jmp = pc_jmp_nxt;

      if(jregs_true)
        o_pc_jmp = rdout_a_nxt[PC_WIDTH + 1 : 2];       //shift 2 left and take wires with width = PC_WIDTH for correct taking address
      
      if(i_branch_en)                                               
        o_pc_jmp = i_pc_branch;
    end
  end 
 
 	assign rdout_a_comb = srs_rdout_a == INC_PC ? {i_inc_pc, 2'b00} : rdout_a_nxt;
	assign sign_bit_nxt = (sign_one & rdout_a_nxt[31]) | (sign_zero & ~rdout_a_nxt[31]);
																								
  //generate control signal for execute stage
	always @(posedge i_clk, negedge i_arst_n) begin
		if(!i_arst_n) begin
			o_rdout_a <= 0;
			o_rdout_b <= 0;
			o_ext_immediate <= 0;
			o_sa <= 0;
			o_alu_ctrl <= 0;
			o_srs_alu_b <= 0;

      o_pc_de	 <= 0;
      o_beq_en <= 1'b0;
      o_bne_en <= 1'b0;

			o_sign_bit <= 1'b0;
			o_nozero <= 1'b0;

			o_sec_alu_en <= 1'b0;
			o_sel_sec_alu <= 1'b0;
			o_sec_alu_op <= 3'b0;
			
			o_wr_instr <= 1'b0;
			o_wr_adr_instr <= 1'b0;
    end else if(kill_decode) begin
      o_beq_en <= 1'b0;
      o_bne_en <= 1'b0;

			o_sign_bit <= 0;
			o_nozero <= 0;

      //if we have command add or sub signed & it comes int then, we need stall alu_ctrl
      //else we have incorrect overflow exeption
      o_alu_ctrl <= 0;
			o_sec_alu_en <= 1'b0;
			
			o_wr_instr <= 1'b0;
			o_wr_adr_instr <= 1'b0;
		end else if(en_decode) begin
	
     	o_beq_en <= beq_en_nxt;
     	o_bne_en <= bne_en_nxt;

			o_sign_bit <= sign_bit_nxt;
			o_nozero <= nozero_nxt;

			o_sec_alu_en <= sec_alu_en_nxt;
			o_sec_alu_op <= sec_alu_op_nxt;
			o_sel_sec_alu <= sel_sec_alu_nxt;
		
			o_alu_ctrl <= alu_ctrl_nxt;
		
			o_rdout_a <= rdout_a_comb;
			o_rdout_b <= rdout_b_nxt;
   		o_pc_de <= i_pc_fe;
			
			o_ext_immediate <= ext_immediate_nxt;
			o_sa <= sa_nxt;
			o_srs_alu_b <= srs_alu_b_nxt;
			
			o_wr_instr <= wr_instr_nxt;
			o_wr_adr_instr <= wr_adr_instr_nxt;

		end
	end

  //generate control signal for memory access stage
	always @(posedge i_clk, negedge i_arst_n) begin
	 	if(!i_arst_n) begin
	 		o_dw_en_de <= 0;
	 		o_dr_en_de <= 0;
			o_dsrs_out_de <= 0;
			o_dsel_width_de <= 0;
		end else if(kill_decode) begin
	 		o_dw_en_de <= 0;
	 		o_dr_en_de <= 0;
		end else if(en_decode) begin
	 		o_dw_en_de <= dw_en_nxt;
	 		o_dr_en_de <= dr_en_nxt;
	 		o_dsrs_out_de <= dsrs_out_nxt;
			
			o_dsel_width_de <= dsel_width_nxt;
	 	end
	 end

   always @* begin
	 	raddr_w_de_nxt = rt;
    case(raddr_dst)
    	RD: raddr_w_de_nxt = rd;
			R31: raddr_w_de_nxt = 5'h1f;
		endcase
   end

  //generate control signal for write back stage
	always @(posedge i_clk, negedge i_arst_n) begin
	 	if(!i_arst_n) begin
	 		o_rw_en_de <= 0;
			o_raddr_w_de <= 0;
		end else if(kill_decode) begin
	 		o_rw_en_de <= 0;
	 	end else if(en_decode) begin
 			o_rw_en_de <= rw_en_nxt | sign_bit_nxt;
      o_raddr_w_de <= raddr_w_de_nxt;
		end
	 end


   //control signals for coprocessor
  always @(posedge i_clk, negedge i_arst_n) begin
    if(!i_arst_n) begin
      o_copr_wen <= 0;
      o_rfe_en <= 0;
      o_copr_addr <= 0;
    end else if(kill_decode) begin
      o_copr_wen <= 0;
      o_rfe_en <= 0;
	 	end else if(en_decode) begin
     	o_rfe_en <= rfe_en_nxt;
     	o_copr_wen <= copr_wen_nxt;
      o_copr_addr <= rd;
		end
  end

endmodule
