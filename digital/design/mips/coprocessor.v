//////////////////////////////////////////////////////////////////////////
//description: control of interrupt & exeption                          //
//////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ps

module coprocessor(i_clk, i_arst_n, i_en, i_address, i_din, i_rfe_en, 
                    i_interrupts, i_delay_slot, i_exceptions,
                    i_pc,
                    o_dout, o_ie_catch, o_int_only);

  parameter DATA_WIDTH = 32;
  parameter PC_WIDTH = 30;
  parameter REG_ADDR_WIDTH = 5;
	parameter	N_INTS = 9;

  //Port declaration
  input                           i_clk;
  input                           i_arst_n;
  input                           i_en;             //enable write
  input [REG_ADDR_WIDTH - 1 : 0]  i_address;
  input [DATA_WIDTH - 1 : 0]      i_din;

  input                           i_rfe_en;            //return from exeption(interrupt)

	input [4 : 0] 									i_exceptions;
	input 													i_delay_slot;
	input [N_INTS - 1 : 0]	 				i_interrupts;


  input [PC_WIDTH - 1 : 0]        i_pc;

  output reg [DATA_WIDTH - 1 : 0] o_dout;

  output                          o_ie_catch;
  output                          o_int_only;     //interrupt received

  //--------------------------internal variable--------------------------
  localparam  QUANTITY_INT = 6 + N_INTS; 

  localparam  STATUS_ADDR = 5'd12,
              CAUSE_ADDR = 5'd13,
              EPC_ADDR = 5'd14;

	integer i;

  reg  [4 : 0] 								mask_exceptions;
  reg  [N_INTS - 1 : 0] 			mask_interrupts;
  reg                         int_all_en;

	reg  [N_INTS - 1 : 0] 			interrupts_ff;
  wire  [4 : 0] 							cause_exceptions;
  wire  [N_INTS - 1 : 0] 			cause_interrupts;
  reg  [N_INTS - 1 : 0] 			pending_interrupts;
  reg  [QUANTITY_INT - 1 : 0] cause;

  reg  [DATA_WIDTH - 1 : 0]   dout_nxt;
	reg [DATA_WIDTH - 1 : 0] 		o_epc;

  //----------------------------------------------------------------------------------------------------------
 	//for detectings front
  always @(posedge i_clk, negedge i_arst_n) begin
		if(!i_arst_n)
			interrupts_ff <= {N_INTS{1'b0}};
		else
			interrupts_ff <= i_interrupts;
	end
	
	assign cause_exceptions = mask_exceptions & i_exceptions & {5{int_all_en}};
	assign cause_interrupts = (mask_interrupts & i_interrupts & ~interrupts_ff) | pending_interrupts;
  assign o_int_only = (|cause_interrupts | (|pending_interrupts)) & int_all_en;
	assign o_ie_catch = o_int_only | (|cause_exceptions);     

  //flip-flop which control all interrupt is allowed or not
  //order is important
  always @(posedge i_clk, negedge i_arst_n) begin
    if(!i_arst_n)
      int_all_en <= 1;
    else if(i_rfe_en)
      int_all_en <= 1;
    else if(o_ie_catch)
      int_all_en <= 0;    //if detect interrupt, than int_all_en = 0
  end

  //what interrupt is allowed
  always @(posedge i_clk, negedge i_arst_n) begin
    if(!i_arst_n) begin
      mask_interrupts <= {N_INTS{1'b1}};
      mask_exceptions <= 5'h1f;
    end else if(i_en & (i_address == STATUS_ADDR)) begin
      mask_interrupts <= i_din[QUANTITY_INT - 1 : 6];
      mask_exceptions <= i_din[4 : 0];
		end
  end
	
	always @(posedge i_clk, negedge i_arst_n) begin
		if(!i_arst_n)
			pending_interrupts <= {N_INTS{1'b0}};
		else begin
			
			if(~int_all_en) begin
				for(i = 0; i < N_INTS; i = i + 1)
					if(cause_interrupts[i])
      			pending_interrupts[i] <= 1'b1;
			end else if(o_ie_catch)
				pending_interrupts <= {N_INTS{1'b0}};
		end
	end

  //what interrupt received
  always @(posedge i_clk, negedge i_arst_n) begin
    if(!i_arst_n)
      cause <= 0;
    else begin

			//exceptions updates only if it is not a handler of int. or exec.
			if(o_ie_catch)
				cause <= {cause_interrupts, i_delay_slot, cause_exceptions};
		
			//allow to make zeros for cause register	
		 	else if(i_en & (i_address == CAUSE_ADDR))
				cause <= i_din[QUANTITY_INT - 1 : 0];
				
		end
  end

  always @(posedge i_clk, negedge i_arst_n) begin
    if(!i_arst_n)
      o_epc <= 0;
    else begin
			if(o_ie_catch)
      	o_epc <= i_pc;
//			else if(i_en & (i_address == EPC_ADDR))
//				o_epc <= i_din[DATA_WIDTH - 1 : 2];    //TODO:here we can receive error: 2lsb need check
		end		
  end

  //generate data out for command(mfc0)
  always @* begin
    dout_nxt = 'h0;
    case(i_address)
      STATUS_ADDR:  dout_nxt = { {DATA_WIDTH - QUANTITY_INT - 1{1'b0}}, mask_interrupts, 1'b0, mask_exceptions};
      CAUSE_ADDR: 	dout_nxt = { {DATA_WIDTH - QUANTITY_INT{1'b0}}, cause};              //int receive
      EPC_ADDR:    	dout_nxt = {o_epc, 2'b00};                                                       
    endcase
  end

  always @(posedge i_clk, negedge i_arst_n) begin
    if(!i_arst_n)
      o_dout <= 0;
    else
      o_dout <= dout_nxt;
  end

endmodule
