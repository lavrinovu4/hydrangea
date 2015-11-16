///////////////////////////////////////////////////////////////////////////
//Description:phase fetch - take new command from memory 		 						 //
///////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ps

module fetch(i_clk, i_arst_n, i_fe_kill, i_jmp_en, i_pc_jmp, i_stall_en, 
						o_pc_fe, o_pc_fe_de, o_instruction);

	parameter INSTR_ADDR_WIDTH 	= 30;
	parameter INSTR_WIDTH 			= 32;
	localparam PC_WIDTH 				= INSTR_ADDR_WIDTH - 2;

	//Port declarations
	input 														i_clk;
	input 														i_arst_n;
	input 														i_jmp_en; 
	input 		  [PC_WIDTH - 1 : 0] 		i_pc_jmp;       //addres for where jump when i_jmp_en = 1 

	input 														i_stall_en;	    //stop load new command if "1" - buble
  input                             i_fe_kill;      //1 - stop load new command  - from coprocessor

	output reg 	[INSTR_WIDTH - 1 : 0] o_instruction;
	output reg  [PC_WIDTH - 1 : 0] 		o_pc_fe;        //program counter for jmp & branch in next stages
	output reg  [PC_WIDTH - 1 : 0] 		o_pc_fe_de;     //program counter for epc   

	//---------------------------Internal variables--------------------
	wire [PC_WIDTH - 2 : 0] 		zero_ext;
	wire [INSTR_WIDTH - 1 : 0] 	instruction_nxt;    //instruction combinational

	wire [PC_WIDTH - 1 : 0]	    inc_pc;             //program counter plus one
	wire 												w_en;               //write enable for program counter and o_instruction
  wire                        kill_fetch;

	//---------------------------Variable assigments-------------------
	assign zero_ext = { PC_WIDTH - 1 { 1'b0 }};
	assign inc_pc = o_pc_fe + { zero_ext, 1'b1 };
	
	assign w_en = !i_stall_en;                      //if stall_en equal zero, then load new command
  assign kill_fetch = i_jmp_en | i_fe_kill;       //if i_jmp_en = 1 or i_fe_kill=1(have interrupt), 
  																								//means jmp & need kill command in instruction flip-flop
	//---------------------------Code starts---------------------------
	//generete new address for read new command
	always @(posedge i_clk, negedge i_arst_n) begin
		if(!i_arst_n)
			o_pc_fe <= 0;
		else begin 
			if(i_jmp_en)
				o_pc_fe <= i_pc_jmp;
			else if (w_en)
				o_pc_fe <= inc_pc;
		end
	end

  //change this module when you will synthes project
	instr_mem #(
		.INSTR_ADDR_WIDTH 	( INSTR_ADDR_WIDTH ))
	 u_instr_mem(
		.i_address			( {o_pc_fe, 2'b00} 		),
		.o_instruction	( instruction_nxt	));


  //generate new instruction and addres of this instruction
	always @(posedge i_clk, negedge i_arst_n) begin
		if(!i_arst_n) begin
			o_pc_fe_de <= 0;
			o_instruction <= 0;
    end else if(kill_fetch)    
      o_instruction <= 0;
		else if(w_en) begin
			o_pc_fe_de <= o_pc_fe;
			o_instruction <= instruction_nxt;
		end
	end

endmodule
