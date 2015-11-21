module cpu_regs (i_ck,
              i_rb,

            i_wb_we,
            i_wb_sel,
            i_wb_adr,
            i_wb_dat,
            i_wb_cyc,
            i_wb_stb,
            o_wb_dat,
            o_wb_ack,

            o_cpu_regs
          );

  input    i_ck;
  input    i_rb;
  input    i_wb_we;
  input [3:0] i_wb_sel;
  input [29:0] i_wb_adr;
  input [31:0] i_wb_dat;
  input i_wb_cyc;
  input i_wb_stb;
  output [31:0] o_wb_dat;
  output o_wb_ack;

  output reg [31:0] o_cpu_regs;

  wire [31:0] mask;

  assign mask = {
  {8{i_wb_sel[3]}},
  {8{i_wb_sel[2]}},
  {8{i_wb_sel[1]}},
  {8{i_wb_sel[0]}}};

  always @(posedge i_ck, negedge i_rb) begin 
    if(!i_rb)
      o_cpu_regs <= 32'h1;
    else
      if(i_wb_stb & i_wb_cyc & i_wb_we)
        o_cpu_regs <= i_wb_dat & mask;
  end
  
  assign o_wb_ack = i_wb_stb & i_wb_cyc;
  assign o_wb_dat = o_cpu_regs;


endmodule