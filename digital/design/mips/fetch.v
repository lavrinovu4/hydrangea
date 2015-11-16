///////////////////////////////////////////////////////////////////////////
//Description:phase fetch - take new command from memory 		 						 //
///////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ps

module fetch(i_clk, i_arst_n, i_ie_catch, i_jmp_en, i_pc_jmp, 
						i_stall_en_de, i_stall_en_ex, i_stall_en_ma,
						i_instr_mem,
						o_pc_fe, o_inc_pc, o_instruction);

	parameter INSTR_ADDR_WIDTH 	= 32;
	parameter INSTR_WIDTH 			= 32;
	localparam PC_WIDTH 				= INSTR_ADDR_WIDTH - 2;

	//Port declarations
	input 														i_clk;
	input 														i_arst_n;
	input 														i_jmp_en; 
	input 		  [PC_WIDTH - 1 : 0] 		i_pc_jmp;       //addres for where jump when i_jmp_en = 1 

	input 		 	[INSTR_WIDTH - 1 : 0] i_instr_mem;
	
	input 														i_stall_en_de;	    //stop load new command if "1" - buble
	input 														i_stall_en_ex;	    //stop load new command if "1" - buble
	input 														i_stall_en_ma;	    //stop load new command if "1" - buble
  input                             i_ie_catch;

	output reg 	[INSTR_WIDTH - 1 : 0] o_instruction;
	output reg  [PC_WIDTH - 1 : 0] 		o_pc_fe;        //program counter for jmp & branch in next stages
	output 			[PC_WIDTH - 1 : 0]	  o_inc_pc;       //program counter plus one   

	wire [INSTR_WIDTH - 1 : 0] 			instruction_nxt;    //instruction combinational

	assign o_inc_pc = o_pc_fe + 1;

	//generete new address for read new command
	always @(posedge i_clk, negedge i_arst_n) begin
		if(!i_arst_n)
			o_pc_fe <= 0;
		else begin
			if(i_ie_catch)
				o_pc_fe <= i_pc_jmp;
			else if(~(i_stall_en_ex | i_stall_en_ma)) begin 
				if(i_jmp_en)
					o_pc_fe <= i_pc_jmp;
				else if(~i_stall_en_de)
					o_pc_fe <= o_inc_pc;
			end
		end
	end

	assign instruction_nxt = i_instr_mem;

  //generate new instruction and addres of this instruction
	always @(posedge i_clk, negedge i_arst_n) begin
		if(!i_arst_n)
			o_instruction <= 0;
    else if(i_ie_catch)    
      o_instruction <= 0;
		else if(~(i_stall_en_de | i_stall_en_ex | i_stall_en_ma))
			o_instruction <= instruction_nxt;
	end

endmodule
