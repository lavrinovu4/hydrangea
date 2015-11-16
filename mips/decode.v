//////////////////////////////////////////////////////////////////////////////////////////////////
//Description:decode stage																																			//
//////////////////////////////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ps

module decode(i_clk, i_arst_n, i_instruction, i_pc_fe, i_pc_fe_de, i_rw_en_wb, i_rdin, i_raddr_w_wb, i_raddr_w_ma, 
      i_pc_branch, i_branch_en, o_stall_en,
      i_epc_out, i_int_catch, i_de_kill,
      o_copr_addr, o_copr_en, o_eret_de, 
			o_rdout_a, o_rdout_b, o_ext_immediate, o_sa, o_srs_alu_b, o_alu_ctrl, 
      o_pc_de_ex, o_pc_de, o_pc_branch_imm, o_beq_en, o_bne_en,
      i_eret_ex, i_eret_ma,
			o_dw_en_de, o_dsrs_out_de, o_pc_jmp, o_jmp_en, o_raddr_w_de, o_rw_en_de,
      o_wr_instr_int, o_valid_de);

	parameter DATA_WIDTH 	    	        = 32;                     //data memory
	parameter INSTR_ADDR_WIDTH 	        = 30;                     //2^30 program memory
	parameter INSTR_WIDTH 		          = 32;
	parameter PC_WIDTH 		              = INSTR_ADDR_WIDTH - 2;
	parameter JMP_IMM_WIDTH 	          = PC_WIDTH - 4;           //for generating jmp
	parameter IMM_WIDTH 		            = 16;                     //for generating data to alu port b
	parameter REG_ADDR_WIDTH 		        = 5;                      //general purpose register
	parameter OPCODE_WIDTH 		          = 6;
	parameter FUNCTION_WIDTH 	          = 6;                     //6 lsb of instruction
	parameter ALU_CTRL_WIDTH 	          = 5; 
  parameter ADDR_TRANSITION_INTERRUPT = 'h1;                    //*4 = addres when interrupt happened 

	`include "func.v"                                     ///for log();
	localparam ADDR_DATA_WIDTH = log(2, DATA_WIDTH);
	
	//Port declaration
	input                                 i_clk;
	input                                 i_arst_n;
	input      [INSTR_WIDTH - 1 : 0]      i_instruction;
	input      [PC_WIDTH - 1 : 0]         i_pc_fe;         //for jmp & branch generating
  input      [PC_WIDTH - 1 : 0]         i_pc_fe_de;     //epc
	input                                 i_rw_en_wb;     //rigester write enable from write back stage
	input      [DATA_WIDTH - 1 : 0]       i_rdin;         //data from write back stage
	input      [REG_ADDR_WIDTH - 1 : 0]   i_raddr_w_wb;   //register addres write from write back stage
	input      [REG_ADDR_WIDTH - 1 : 0]   i_raddr_w_ma;   //from memory access stage
  input                                 i_eret_ex;
  input                                 i_eret_ma;
  input                                 i_branch_en;
  input      [PC_WIDTH - 1 : 0]         i_pc_branch;
  input                                 i_int_catch;    //interrupt happened = 1
  input      [DATA_WIDTH - 1 : 0]       i_epc_out;      //from coprocessor = pc where need bach for continue program

  input                                 i_de_kill;	    //if have interrupt need kill this stage

  output reg                            o_beq_en;       //branch if equal enable
  output reg                            o_bne_en;       //branch if not equal enable
  output reg [PC_WIDTH - 1 : 0]         o_pc_de;        //for generating bracnch in next stage, repeat i_pc_fe
  output reg [PC_WIDTH - 1 : 0]         o_pc_de_ex;      //for epc, repeat i_pc_fe_de
  output reg [PC_WIDTH - 1 : 0]         o_pc_branch_imm;  //second add for create address of branch
	output reg [DATA_WIDTH - 1 : 0]       o_rdout_a;        //register data out port a
	output reg [DATA_WIDTH - 1 : 0]       o_rdout_b;        //register data out port b
	output reg [DATA_WIDTH - 1 : 0]       o_ext_immediate;  //data after extender
	output reg [ADDR_DATA_WIDTH - 1 : 0]  o_sa;             //shift amount
	output reg                            o_srs_alu_b;
	output reg [ALU_CTRL_WIDTH - 1 : 0]   o_alu_ctrl; 
	output reg [PC_WIDTH - 1 : 0]         o_pc_jmp;          //new program counter if we have j, branch, eret, int, jr
	output                                o_jmp_en;          //jump enable
	output reg [REG_ADDR_WIDTH - 1 : 0]   o_raddr_w_de;      //register address write from decode stage - control signals for next stages
	output reg                            o_rw_en_de;
	output reg                            o_dw_en_de;
	output reg [1 : 0]                    o_dsrs_out_de;

  output reg [REG_ADDR_WIDTH - 1 : 0]   o_copr_addr;
  output reg                            o_copr_en;
  output reg                            o_eret_de;

	output                                o_stall_en;     //load "nop" if "1"
  output                                o_wr_instr_int;
  output                                o_valid_de;      //are there command which need do next stages??no - 1

	//-----------------------------------------Internal variables--------------------------------
	wire [OPCODE_WIDTH - 1 : 0]     opcode;       //operation code from instruction
	wire [REG_ADDR_WIDTH - 1 : 0]   rs;           //read register source address
	wire [REG_ADDR_WIDTH - 1 : 0]   rt;	          //read register second sourse address

  wire [REG_ADDR_WIDTH - 1 : 0] 	rd;                  //register destination address
	wire [ADDR_DATA_WIDTH - 1 : 0] 	sa_nxt;                  //shift amount
	wire [FUNCTION_WIDTH - 1 : 0] 	alu_func;

	wire [IMM_WIDTH - 1 : 0] 	      immediate;
	wire [JMP_IMM_WIDTH - 1 : 0] 	  imm_jmp;
  wire [PC_WIDTH - 1 : 0]         pc_branch_immediate_nxt;
  wire [PC_WIDTH - 1 : 0]         pc_jmp_nxt;
  wire                            jmp_en_nxt;

	wire [DATA_WIDTH - 1 : 0]       rdout_a_nxt;             //regiter data out port a 
	wire [DATA_WIDTH - 1 : 0]       rdout_b_nxt;             //regiter data out port a 
	wire [DATA_WIDTH - 1 : 0]       ext_immediate_nxt;
	wire                            srs_alu_b_nxt;
	wire                            extend_operation;
	wire [ALU_CTRL_WIDTH - 1 : 0]   alu_ctrl_nxt;
	wire [1 : 0]                    dsrs_out_nxt;
	wire                            raddr_dst;               //register addres destination rt or rd
  reg  [REG_ADDR_WIDTH - 1 : 0]   raddr_w_de_nxt;
	wire                            rw_en_nxt;
	wire                            beq_en_nxt;
	wire                            bne_en_nxt;
	wire                            dw_en_nxt;                    //data write enable

	wire                            wrong_instr_alu_cu;
  wire                            wrong_instr_mipc_cu;

  wire                            kill_decode;
  wire                            copr_en_nxt;
  wire                            copr_re;
  wire                            copr_wr_instr;
  wire                            eret_nxt;

  wire                            jr_true;

  `include "local_params.v"    //JR
	//-------------------------------------------Variable assigments-------------------------------
	assign {opcode, rs, rt, rd, sa_nxt, alu_func} = i_instruction;
	assign immediate = i_instruction[IMM_WIDTH - 1 : 0];
	assign imm_jmp = i_instruction[JMP_IMM_WIDTH - 1 : 0];

	assign pc_jmp_nxt = {i_pc_fe[PC_WIDTH - 1 : JMP_IMM_WIDTH], imm_jmp};
  assign pc_branch_immediate_nxt = { {PC_WIDTH - IMM_WIDTH {immediate[IMM_WIDTH - 1]}}, immediate};

	assign o_jmp_en = jmp_en_nxt | i_branch_en | i_int_catch | jr_true | eret_nxt;
  assign o_wr_instr_int = wrong_instr_mipc_cu | wrong_instr_alu_cu | copr_wr_instr;

  assign kill_decode = i_de_kill | o_stall_en;

  assign jr_true = (alu_func == JR) && (opcode == R_TYPE);

  assign o_valid_de = (|raddr_w_de_nxt & rw_en_nxt) | dw_en_nxt | jmp_en_nxt;
  //-------------------------------------------Code starts----------------------------------------

  //general purpose registers
	register_file u_register_file(
		.i_clk							( i_clk 					  	),
		.i_addr_ra					( rs 	  					  	),
		.i_addr_rb					( rt  						  	),
		.i_w_en 						( i_rw_en_wb 			  	),
		.i_addr_w 					( i_raddr_w_wb		  	),
		.i_din    					( i_rdin 					  	),
		.o_dout_ra 					( rdout_a_nxt 		  	),
		.o_dout_rb 					( rdout_b_nxt 		  	));

	extender #(
		.DATA_WIDTH			( IMM_WIDTH 		),
		.DATA_EXT_WIDTH	( DATA_WIDTH 		))
	 u_extender(
		.i_operation 				( extend_operation  	),
		.i_din 							( immediate 			  	),
		.o_dout     				( ext_immediate_nxt  	));

	
	alu_cu #(
		.ALU_CTRL_WIDTH	( ALU_CTRL_WIDTH))
	 u_alu_cu(
		.i_function					( alu_func 						),
		.i_opcode						( opcode 	  					),
		.o_alu_ctrl					( alu_ctrl_nxt 				),
		.o_wrong_instr		 	( wrong_instr_alu_cu	));               

	mips_cu u_mips_cu(
		.i_opcode 					( opcode   				  	),
		.o_raddr_dst				( raddr_dst				  	),
		.o_dsrs_out 				( dsrs_out_nxt		  	),
		.o_rw_en						( rw_en_nxt 			  	),
		.o_dw_en 						( dw_en_nxt 					),
		.o_extend_operation ( extend_operation 	  ),
		.o_srs_alu_b 				( srs_alu_b_nxt 		  ),
		.o_jmp_en 					( jmp_en_nxt 	 			  ),
		.o_beq_en 			    ( beq_en_nxt 	        ),
		.o_bne_en 			    ( bne_en_nxt 	        ),
    .o_wrong_instruction( wrong_instr_mipc_cu ));
 
 	hazard_cu u_hazard_cu(
		.i_opcode 				( opcode 				),
    .i_branch_en      ( i_branch_en   ),
		.i_rs 						( rs 						), 
		.i_rt 						( rt 						), 
		.i_ws_ex					( o_raddr_w_de	), 
		.i_ws_ma					( i_raddr_w_ma	), 
		.i_ws_wb					( i_raddr_w_wb	),
    .i_eret_de        ( o_eret_de     ),
    .i_eret_ex        ( i_eret_ex     ),
    .i_eret_ma        ( i_eret_ma     ),
		.o_stall_en 			( o_stall_en 		));

  coprocessor_cu u_coprocessor_cu(
    .i_opcode         ( opcode        ),
    .i_copr_code      ( rs            ),    //copr_code decode from range of rs in i_instruction
    .o_eret           ( eret_nxt       ),
    .o_copr_we        ( copr_en_nxt   ),
    .o_copr_re        ( copr_re       ),
    .o_copr_wr_instr  ( copr_wr_instr ));

  //generate new program counter if we have one of types of jmp
  always @* begin
    if(i_int_catch)
        o_pc_jmp = ADDR_TRANSITION_INTERRUPT;
    else begin
      o_pc_jmp = pc_jmp_nxt;
     
      if(eret_nxt)
        o_pc_jmp <= i_epc_out[PC_WIDTH + 1 : 2];

      if(jr_true)
        o_pc_jmp = rdout_a_nxt[PC_WIDTH + 1 : 2];       //shift 2 left and take wires with width = PC_WIDTH for correct taking address
      
      if(i_branch_en)                                               
        o_pc_jmp = i_pc_branch;
    end
  end 
 
  //generate control signal for execute stage
	always @(posedge i_clk, negedge i_arst_n) begin
		if(!i_arst_n) begin
			o_rdout_a <= 0;
			o_rdout_b <= 0;
			o_ext_immediate <= 0;
			o_sa <= 0;
			o_alu_ctrl <= 0;
			o_srs_alu_b <= 0;

      o_pc_de_ex <= 0;
      o_pc_de <= 0;
      o_pc_branch_imm <= 0;
      o_beq_en <= 1'b0;
      o_bne_en <= 1'b0;
    end else if(kill_decode) begin
      o_beq_en <= 1'b0;
      o_bne_en <= 1'b0;

      //if we have command add or sub signed & it comes int then, we need stall alu_ctrl
      //else we have incorrect overflow exeption
      o_alu_ctrl <= {ALU_CTRL_WIDTH{1'b0}};
    end else begin
			o_rdout_a <= rdout_a_nxt;
			o_rdout_b <= rdout_b_nxt;
			o_ext_immediate <= ext_immediate_nxt;
			o_sa <= sa_nxt;
			o_alu_ctrl <= alu_ctrl_nxt;
			o_srs_alu_b <= srs_alu_b_nxt;
      
      o_pc_de <= i_pc_fe;
      o_pc_de_ex <= i_pc_fe_de;
      o_pc_branch_imm <= pc_branch_immediate_nxt;

      o_beq_en <= beq_en_nxt;
      o_bne_en <= bne_en_nxt;
		end
	end

  //generate control signal for memory access stage
	always @(posedge i_clk, negedge i_arst_n) begin
	 	if(!i_arst_n) begin
	 		o_dw_en_de <= 0;
			o_dsrs_out_de <= 0;
		end else if(kill_decode) begin
	 		o_dw_en_de <= 0;
	 	end else begin
	 		o_dw_en_de <= dw_en_nxt;
	 		o_dsrs_out_de <= dsrs_out_nxt;
	 	end
	 end

   always @* begin
    if(raddr_dst)
      raddr_w_de_nxt = rd;
    else                                   
      raddr_w_de_nxt = rt;  
   end

  //generate control signal for write back stage
	always @(posedge i_clk, negedge i_arst_n) begin
	 	if(!i_arst_n) begin
	 		o_rw_en_de <= 0;
			o_raddr_w_de <= 0;
		end else if(kill_decode) begin
			o_raddr_w_de <= 0;
	 		o_rw_en_de <= 0;
	 	end else begin
	 		o_rw_en_de <= rw_en_nxt | copr_re;       //2 sousre for write to register file
	 		                                         //one - mips_cu as usual, and coprocessor_cu (i can`t decode this wire in mips_cu,
				                                       //because, i will need transmitt all instruction code to mips_cu, that is why i created coprocessor_cu
      o_raddr_w_de <= raddr_w_de_nxt;
	 	end
	 end


   //control signals for coprocessor
  always @(posedge i_clk, negedge i_arst_n) begin
    if(!i_arst_n) begin
      o_copr_en <= 0;
      o_eret_de <= 0;
      o_copr_addr <= 0;
    end else if(o_stall_en) begin
      o_copr_en <= 0;
      o_eret_de <= 0;
    end else begin
      o_eret_de <= eret_nxt;
      o_copr_en <= copr_en_nxt;
      o_copr_addr <= rd;
    end
  end

endmodule
