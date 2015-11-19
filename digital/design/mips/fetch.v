///////////////////////////////////////////////////////////////////////////
//Description:phase fetch - take new command from memory 		 						 //
///////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ps

module fetch(i_clk, i_arst_n, i_core_en, i_ie_catch, i_jmp_en, i_pc_jmp, 
						i_stall_en_de, i_stall_en_ex, i_stall_en_ma,
						i_instr_mem,
						o_pc_fe, o_inc_pc, o_instruction, o_read_req, i_read_ack, o_stall_en_fe);

	parameter PC_START_ADDRRES 	= 0;
	parameter INSTR_ADDR_WIDTH 	= 32;
	parameter INSTR_WIDTH 			= 32;
	localparam PC_WIDTH 				= INSTR_ADDR_WIDTH - 2;

	//Port declarations
	input 														i_clk;
	input 														i_arst_n;
	input 														i_core_en;
	input 														i_jmp_en; 
	input 		  [PC_WIDTH - 1 : 0] 		i_pc_jmp;       //addres for where jump when i_jmp_en = 1 

	input 		 	[INSTR_WIDTH - 1 : 0] i_instr_mem;
	
	input 														i_stall_en_de;	    //stop load new command if "1" - buble
	input 														i_stall_en_ex;	    //stop load new command if "1" - buble
	input 														i_stall_en_ma;	    //stop load new command if "1" - buble
  input                             i_ie_catch;

  input 														i_read_ack;

	output reg 	[INSTR_WIDTH - 1 : 0] o_instruction;
	output reg  [PC_WIDTH - 1 : 0] 		o_pc_fe;        //program counter for jmp & branch in next stages
	output 			[PC_WIDTH - 1 : 0]	  o_inc_pc;       //program counter plus one   
	output 														o_read_req;

	output 														o_stall_en_fe;

	wire [INSTR_WIDTH - 1 : 0] 			instruction_nxt;    //instruction combinational
	wire 														read_stall;

	reg 														stall;

	assign o_inc_pc = o_pc_fe + 1;

	always @* begin
		stall = 1;
		if (~(i_stall_en_ex | i_stall_en_ma))
			if(i_jmp_en)
				stall = 0;
			else if(~i_stall_en_de)
				stall = 0;
	end

	//generete new address for read new command
	always @(posedge i_clk, negedge i_arst_n) begin
		if(!i_arst_n)
			o_pc_fe <= PC_START_ADDRRES;
		else if(~i_core_en)
			o_pc_fe <= PC_START_ADDRRES;
		else begin
			if(i_ie_catch | (i_jmp_en & ~read_stall))
				o_pc_fe <= i_pc_jmp;
			else if(~read_stall)
				o_pc_fe <= o_inc_pc;
		end
	end

	assign instruction_nxt = i_instr_mem;

	assign o_read_req = ~stall & i_core_en;
	assign read_stall = (o_read_req & ~i_read_ack) | stall;

	assign o_stall_en_fe = (i_jmp_en | i_ie_catch) & (o_read_req & ~i_read_ack);
  //generate new instruction and addres of this instruction
	always @(posedge i_clk, negedge i_arst_n) begin
		if(!i_arst_n)
			o_instruction <= 0;
    else if(i_ie_catch | (read_stall & ~stall & ~i_jmp_en))    
      o_instruction <= 0;
		else if(o_read_req & i_read_ack)
			o_instruction <= instruction_nxt;
	end

endmodule
