/////////////////////////////////////////////////////////////////////
//Desription:model of memory for MIPS                              //
/////////////////////////////////////////////////////////////////////

`timescale 1ns/1ps
//`define CONST_EN

module memory(i_clk, i_address, i_sel_width, i_w_en, i_din, o_dout);

  //Port declarations
  input                               i_clk;
  input   [29 : 0]                    i_address;
  input   [3 : 0]                     i_sel_width;
  input                               i_w_en;
  input   [31 : 0]                    i_din;
  output  [31 : 0]                    o_dout;

  //----------------------Internal variables---------------------
  reg  [31 : 0] mem [0 : 2**21 - 1];    //2M * 31b = 8MB 

  reg  [31 : 0] read_mask;
  wire [31 : 0] read_data;

  wire  [31 : 0] write_data;
  reg [31 :0] write_mask;
  //----------------------Variable assigments--------------------
  //async read
  assign read_data = mem[i_address[20 : 0]];

  //----------------------Code start-----------------------------
  
  always @(i_sel_width) begin
    read_mask = 31'b0;
    if(i_sel_width[3])
      read_mask[31 : 24] = 8'hff; 
    
    if(i_sel_width[2])
      read_mask[23 : 16] = 8'hff; 

    if(i_sel_width[1])
      read_mask[15 : 8] = 8'hff; 

    if(i_sel_width[0])
      read_mask[7 : 0] = 8'hff; 
  end 
  
  assign o_dout = read_data & read_mask;

  always @(i_sel_width) begin
    write_mask = 31'b0;
    if(i_sel_width[3])
      write_mask[31 : 24] = 8'hff; 
    
    if(i_sel_width[2])
      write_mask[23 : 16] = 8'hff; 

    if(i_sel_width[1])
      write_mask[15 : 8] = 8'hff; 

    if(i_sel_width[0])
      write_mask[7 : 0] = 8'hff; 
  end

  assign write_data = (i_din & write_mask) | (read_data & ~write_mask);

  //sync write
  always @(posedge i_clk) begin
    if(i_w_en)
      mem[i_address[20 : 0]] <= write_data;
  end
  
endmodule