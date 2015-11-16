// ---------------------------------------------------------------------------
//
// Description:
//
// Created:     Wed Oct 22 16:58:11 EEST 2014
//      by:     vkh
// ---------------------------------------------------------------------------

module additional_alu(i_clk, i_arst_n, i_en, i_operation,
											i_data_a, i_data_b, o_busy, o_div_zero, o_dout);

	parameter DATA_WIDTH = 32;
	parameter OPERATION_WIDTH = 3;

	input i_clk;
	input i_arst_n;
	input i_en;
	input [OPERATION_WIDTH - 1 : 0] i_operation;
	
	input [DATA_WIDTH - 1 : 0] i_data_a;
	input [DATA_WIDTH - 1 : 0] i_data_b;

	output reg [DATA_WIDTH - 1 : 0] o_dout;
	output reg o_busy;
	output o_div_zero;

// -------------------------------------------------------------------------
	reg [DATA_WIDTH - 1 : 0] data_b;
	reg [DATA_WIDTH - 1 : 0] high;
	reg [DATA_WIDTH - 1 : 0] low;

	wire [DATA_WIDTH - 1 : 0] data_b_nxt;
	reg [DATA_WIDTH - 1 : 0] high_nxt;
	reg [DATA_WIDTH - 1 : 0] low_nxt;

	reg high_en;
	reg low_en;

	wire state_en;
	wire div_en;
	wire sign;
	wire mult_en;
	wire lo_adr;
	wire hi_adr;

	reg div_en_ff;
	reg sign_data_a;
	reg sign_data_b;

	wire lo_read_sel;
	wire hi_read_sel;

	reg sub_true;
	wire carry;
	wire [DATA_WIDTH - 1 : 0] alu_result;

	reg low_shl;
	reg carry_nxt;
	reg carry_ff;

	wire [DATA_WIDTH - 1 : 0] data_a_after_sign;
	wire [DATA_WIDTH - 1 :0] high_after_sign;
	wire [DATA_WIDTH - 1 :0] low_after_sign;
	wire 										 carry_low;

	reg [6 : 0] counter;
	wire counter_end;
	reg counter_en;

	reg [2 : 0] state;

	parameter IDDLE 			= 3'h0,
						START_MULT 	= 3'h1,
						ADD 				= 3'h2,
						SUB					= 3'h3,
						SHL 				= 3'h4,
						SHR		 			= 3'h5;

// -------------------------------------------------------------------------
	assign state_mashine_en = i_en & i_operation[2];
	assign state_en = state_mashine_en & ~o_div_zero;
	assign div_en = i_operation[1] & state_mashine_en;
	assign mult_en = ~i_operation[1] & state_mashine_en;
	assign sign = ~i_operation[0];
	assign {lo_adr, write} = i_operation[1 : 0];
	assign hi_adr = ~lo_adr;

	assign o_div_zero = (i_data_b == 0) & div_en;

	always @(posedge i_clk, negedge i_arst_n) begin
		if(!i_arst_n) 
			div_en_ff <= 1'b0;
		else if(state_en)
			div_en_ff <= div_en;
	end

	always @(posedge i_clk, negedge i_arst_n) begin
		if(!i_arst_n) begin
			sign_data_a <= 1'b0;
			sign_data_b <= 1'b0;
		end else if(state_en) begin
			sign_data_a <= i_data_a[DATA_WIDTH - 1] & sign;
			sign_data_b <= i_data_b[DATA_WIDTH - 1] & sign;
		end
	end

	assign lo_read_sel = sign_data_a ^ sign_data_b;
	assign hi_read_sel = (div_en_ff & sign_data_a) | (~div_en_ff & lo_read_sel);

	sign_unsign_mux u_sign_data_b(.i_sel(sign & i_data_b[DATA_WIDTH - 1]), .i_data(i_data_b), .o_dout(data_b_nxt));

	always @(posedge i_clk, negedge i_arst_n) begin
		if(!i_arst_n)
			data_b <= 0;
		else if(state_en)
			data_b <= data_b_nxt;
	end
	
//	assign {carry, o_dout} = {1'b0, high, sub_true} + {1'b0, {32{sub_true}} ^ data_b, sub_true} >> 1;	
	assign {carry, alu_result} = sub_true ?  high - data_b : high + data_b;

	always @(posedge i_clk, negedge i_arst_n) begin
		if(!i_arst_n)
			low_shl <= 1'b0;
		else
			low_shl <= ~carry;
	end

	always @(posedge i_clk, negedge i_arst_n) begin
		if(!i_arst_n)
			carry_ff <= 1'b0;
		else
			carry_ff <= carry_nxt;
	end


	always @(posedge i_clk, negedge i_arst_n) begin
		if(!i_arst_n)
			high <= 0;
		else if(state_en)
			high <= 0;
		else if(high_en)
			high <= high_nxt;
	end

	sign_unsign_mux u_sign_low(.i_sel(sign & i_data_a[DATA_WIDTH - 1]), .i_data(i_data_a), .o_dout(data_a_after_sign));
	
	always @(posedge i_clk, negedge i_arst_n) begin
		if(!i_arst_n)
			low <= 0;
		else if(low_en)
			low <= low_nxt;
	end

	assign {carry_low, low_after_sign} = (low ^ {DATA_WIDTH{lo_read_sel}}) + {{DATA_WIDTH - 1{1'b0}}, lo_read_sel};
	assign high_after_sign = (high ^ {DATA_WIDTH{hi_read_sel}}) + {{DATA_WIDTH - 1{1'b0}}, hi_read_sel & (div_en_ff | carry_low)};
	
	always @(lo_adr, high_after_sign, low_after_sign) begin
		if(lo_adr == 1'b1)
			o_dout = low_after_sign;
		else
			o_dout = high_after_sign;
	end

	always @(posedge i_clk, negedge i_arst_n) begin
		if(!i_arst_n)
			counter <= 6'h0;
		else if(counter_end & counter_en)
			counter <= 6'h0;
		else if(counter_en)
			counter <= counter + 6'h1;
	end

	assign counter_end = counter == 6'h20;

	always @(posedge i_clk, negedge i_arst_n) begin
		if(!i_arst_n)
			state <= IDDLE;
		else begin
			case(state)
				IDDLE:begin
					if(state_en) begin
						if(mult_en)
							state <= SHR;
						else if(div_en)
							state <= SUB;
					end
				end
				SUB: begin
					if(carry == 1'b1)
						state <= ADD;
					else
						state <= SHL;
				end
				ADD: begin
					if(div_en_ff)
						state <= SHL;
					else
						state <= SHR;
				end
				SHR: begin
					if(counter_end == 1'b1)
						state <= IDDLE;
					else if(low[0] == 1'b1)
						state <= ADD;
				end
				SHL: begin
					if(counter_end == 1'b1)
						state <= IDDLE;
					else
						state <= SUB;
				end
			endcase
		end
	end

	always @(state, high, low, carry, low_shl, state_en, alu_result, i_data_a, data_a_after_sign,
					 lo_adr, hi_adr, i_en, write) begin
		high_nxt = i_data_a;
		sub_true = 1'b0;
		low_nxt = data_a_after_sign;
		o_busy = 1'b0;
		low_en = 1'b0;
		high_en = 1'b0;
		counter_en = 1'b0;
		carry_nxt = 1'b0;
		case(state)
			SHR: begin
				high_nxt = {carry_ff, high[31 : 1]};
				low_nxt = {high[0], low[31 : 1]};
				o_busy = 1'b1;
				low_en = 1'b1;
				high_en = 1'b1;
				counter_en = 1'b1;
				carry_nxt = 1'b0;
			end
			SHL: begin
				high_nxt = {high[30 : 0], low[31]};
				low_nxt = {low[30 : 0], low_shl};
				o_busy = 1'b1;
				low_en = 1'b1;
				high_en = ~counter_end;
				counter_en = 1'b1;
			end
			ADD: begin
			 	high_nxt = alu_result;
				sub_true = 1'b0;
				o_busy = 1'b1;
				high_en = 1'b1;
				carry_nxt = carry;
			end
			SUB: begin
			 	high_nxt = alu_result;
				sub_true = 1'b1;
				o_busy = 1'b1;
				high_en = 1'b1;
			end
			IDDLE: begin
				high_nxt = i_data_a;
				low_nxt = data_a_after_sign;
				o_busy = 1'b0;
				low_en = lo_adr & i_en & write | state_en;
				high_en = hi_adr & i_en & write;
			end
		endcase
	end

endmodule

module sign_unsign_mux(i_sel, i_data, o_dout);
	parameter DATA_WIDTH = 32;
	
	input i_sel;
	input [DATA_WIDTH - 1 : 0] i_data;
	output [DATA_WIDTH - 1 : 0] o_dout;

	assign o_dout = (i_data ^ {DATA_WIDTH{i_sel}}) + {31'b0, i_sel};

endmodule
