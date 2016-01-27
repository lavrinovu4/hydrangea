module sram_cache (
  i_ck,
  i_addr,
  i_we,
  i_data_w,

  o_data_r
);
  parameter ADDR_WIDTH = 30;
  parameter DATA_WIDTH = 32;

  input                     i_ck     ;
  input [ADDR_WIDTH - 1:0]  i_addr   ;
  input [DATA_WIDTH - 1:0]  i_data_w ;
  input                     i_we     ;

  output [DATA_WIDTH - 1:0] o_data_r ;


  reg [ADDR_WIDTH - 1:0] addr_rg;
  reg [DATA_WIDTH - 1:0] data_w_rg;
  reg                    we_rg; 

  reg [DATA_WIDTH - 1:0] mem [2**ADDR_WIDTH - 1:0];

  integer i;

  initial begin
    for(i = 0; i < 2**ADDR_WIDTH; i = i + 1)
      mem[i] = 0;
  end

  always @(posedge i_ck) begin
    addr_rg <= i_addr;
    we_rg <= i_we;
    data_w_rg <= i_data_w;

    if(we_rg)
      mem[addr_rg] <= data_w_rg;
  end

  assign o_data_r = mem[addr_rg];

endmodule