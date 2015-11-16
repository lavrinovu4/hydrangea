//////////////////////////////////////////////////////////////////////////
//description: control of interrupt & exeption                          //
//////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ps

module coprocessor(i_clk, i_arst_n, i_en, i_address, i_din, i_eret, 
                    i_external_int, i_ovf_int, i_wr_instr_int, i_wr_addr_data,
                    i_pc_fe, i_pc_fe_de, i_pc_de_ex, i_pc_ex_ma, i_valid_ma, i_valid_ex, i_valid_de,
                    o_dout, o_epc, o_ma_kill, o_ex_kill, o_de_kill, o_int_true);

  parameter DATA_WIDTH = 32;
  parameter PC_WIDTH = 30;
  parameter REG_ADDR_WIDTH = 5;

  //Port declaration
  input                           i_clk;
  input                           i_arst_n;
  input                           i_en;             //enable write
  input [REG_ADDR_WIDTH - 1 : 0]  i_address;
  input [DATA_WIDTH - 1 : 0]      i_din;
  input                           i_eret;            //return from exeption(interrupt)
  input                           i_external_int;
  input                           i_ovf_int;
  input                           i_wr_instr_int;
  input                           i_wr_addr_data;
  
  input [PC_WIDTH - 1 : 0]        i_pc_fe;
  input [PC_WIDTH - 1 : 0]        i_pc_fe_de;
  input [PC_WIDTH - 1 : 0]        i_pc_de_ex;
  input [PC_WIDTH - 1 : 0]        i_pc_ex_ma;

  input                           i_valid_ma;
  input                           i_valid_ex;
  input                           i_valid_de;

  output reg [DATA_WIDTH - 1 : 0] o_dout;
  output reg [DATA_WIDTH - 1 : 0] o_epc;
  output                          o_ma_kill;
  output                          o_ex_kill;
  output                          o_de_kill;

  output                          o_int_true;     //interrupt received

  //--------------------------internal variable--------------------------
  localparam  QUANTITY_INT = 4; 
  localparam  EXT_INT = 3,
              WR_ADDR_DATA = 2,
              OVF_INT = 1,
              WR_INSTR_INT = 0; 

  localparam  MASK_ADDR = 5'd12,
              SOURSE_ADDR = 5'd13,
              EPC_ADDR = 5'd14;

  localparam  MA = 3,
              EX = 2,
              DE = 1,
              FE = 0;

  reg  [QUANTITY_INT - 1 : 0] mask;
  reg                         int_all_en;
  reg  [QUANTITY_INT - 1 : 0] sourse;
  wire [QUANTITY_INT - 1 : 0] int;
  wire [QUANTITY_INT - 1 : 0] sourse_nxt;
  wire [QUANTITY_INT - 1 : 0] srs_epc;

  reg  [DATA_WIDTH - 1 : 0]   epc_nxt;
  reg  [DATA_WIDTH - 1 : 0]   dout_nxt;

  wire                        ext_int_en;
  wire                        ovf_int_en;
  wire                        wr_addr_data_en;
  wire                        wr_instr_int_en;
  //--------------------------variable assigments-------------------------
  assign int = {i_external_int, i_wr_addr_data, i_ovf_int, i_wr_instr_int};   //interrupt which come
  assign sourse_nxt = mask & int;                             //interrupt which come & checked if they are enable
  assign srs_epc = sourse_nxt & {QUANTITY_INT{ int_all_en}};  //upper + int_all_en
  assign o_int_true = |srs_epc;                               //if one interrupt went throught all check  then true

  assign {ext_int_en, wr_addr_data_en, ovf_int_en, wr_instr_int_en} = srs_epc; //decode interrupt for choosing which stage we must kill
  
  //valid determinate this command need for savining or command done, and saving this command mean that it will repaet(we dont need so)
  //external interrupt kill all but not write back
  // write back i dont kill because it dont have any source of interrupt & coprocessor never will skip interrupt from this stage
  //wr_addr_data - kill memory acces & execution & decode 
  //overflow - kill execution & decode stage
  //wrong instruction - kill decode stage
  //fetch stage are killed every time when we have interrupt 
  assign o_ma_kill = (ext_int_en | wr_addr_data_en) & i_valid_ma;                          
  assign o_ex_kill = (ext_int_en | wr_addr_data_en | ovf_int_en) & i_valid_ex;                 
  assign o_de_kill = (ext_int_en | wr_addr_data_en | ovf_int_en | wr_instr_int_en) & i_valid_de;
  //--------------------------code start---------------------------------- 
 
  //flip-flop which control all interrupt is allowed or not
  //order is imporatant
  always @(posedge i_clk, negedge i_arst_n) begin
    if(!i_arst_n)
      int_all_en <= 0;
    else if(i_eret)
      int_all_en <= 1;
    else if(o_int_true)
      int_all_en <= 0;    //if detect interrupt, than int_all_en = 0
    else if(i_en & (i_address == MASK_ADDR))
      int_all_en <= i_din[QUANTITY_INT];
  end

  //what interrupt is allowed
  always @(posedge i_clk, negedge i_arst_n) begin
    if(!i_arst_n)
      mask <= 0;
    else if(i_en & (i_address == MASK_ADDR))
      mask <= i_din[QUANTITY_INT - 1 : 0];
  end

  //what interrupt received
  always @(posedge i_clk, negedge i_arst_n) begin
    if(!i_arst_n)
      sourse <= 0;
    else if(int_all_en)
      sourse <= sourse_nxt;
  end

  //here order is important(higher must be pc in the end of pipeline)
  always @* begin
    epc_nxt = {{DATA_WIDTH - PC_WIDTH - 2{1'b0}}, i_pc_fe, 2'b00};
    if(o_de_kill)
      epc_nxt = {{DATA_WIDTH - PC_WIDTH - 2{1'b0}}, i_pc_fe_de, 2'b00};
    if(o_ex_kill)
      epc_nxt = {{DATA_WIDTH - PC_WIDTH - 2{1'b0}}, i_pc_de_ex, 2'b00};
    if(o_ma_kill)
      epc_nxt = {{DATA_WIDTH - PC_WIDTH - 2{1'b0}}, i_pc_ex_ma, 2'b00};
  end

  always @(posedge i_clk, negedge i_arst_n) begin
    if(!i_arst_n)
      o_epc <= 0;
    else if(o_int_true)
      o_epc <= epc_nxt;
  end

  //generate data out for command(mfc0)
  always @* begin
    dout_nxt = 'h0;
    case(i_address)
      MASK_ADDR:   dout_nxt = { {DATA_WIDTH - QUANTITY_INT - 1{1'b0}}, int_all_en, mask};//enable int + mask
      SOURSE_ADDR: dout_nxt = { {DATA_WIDTH - QUANTITY_INT{1'b0}}, sourse};              //int receive
      EPC_ADDR:    dout_nxt = o_epc;                                                       
    endcase
  end

  always @(posedge i_clk, negedge i_arst_n) begin
    if(!i_arst_n)
      o_dout <= 0;
    else
      o_dout <= dout_nxt;
  end

endmodule
