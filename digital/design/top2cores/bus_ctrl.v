

module bus_ctrl #(
parameter WB_DWIDTH  = 32,
parameter WB_SWIDTH  = 4
)(

input                       i_wb_clk,     // WISHBONE clock
    input i_arst_n,

// WISHBONE master 0 - Ethmac
input       [31:0]          i_m0_wb_adr,
input       [WB_SWIDTH-1:0] i_m0_wb_sel,
input                       i_m0_wb_we,
output      [WB_DWIDTH-1:0] o_m0_wb_dat,
input       [WB_DWIDTH-1:0] i_m0_wb_dat,
input                       i_m0_wb_cyc,
input                       i_m0_wb_stb,
output                      o_m0_wb_ack,

// WISHBONE master 1 - Amber
input       [31:0]          i_m1_wb_adr,
input       [WB_SWIDTH-1:0] i_m1_wb_sel,
input                       i_m1_wb_we,
output      [WB_DWIDTH-1:0] o_m1_wb_dat,
input       [WB_DWIDTH-1:0] i_m1_wb_dat,
input                       i_m1_wb_cyc,
input                       i_m1_wb_stb,
output                      o_m1_wb_ack,


// WISHBONE slave 0 - Ethmac
output      [31:0]          o_s0_wb_adr,
output      [WB_SWIDTH-1:0] o_s0_wb_sel,
output                      o_s0_wb_we,
input       [WB_DWIDTH-1:0] i_s0_wb_dat,
output      [WB_DWIDTH-1:0] o_s0_wb_dat,
output                      o_s0_wb_cyc,
output                      o_s0_wb_stb,
input                       i_s0_wb_ack,


// WISHBONE slave 1 - Boot Memory
output      [31:0]          o_s1_wb_adr,
output      [WB_SWIDTH-1:0] o_s1_wb_sel,
output                      o_s1_wb_we,
input       [WB_DWIDTH-1:0] i_s1_wb_dat,
output      [WB_DWIDTH-1:0] o_s1_wb_dat,
output                      o_s1_wb_cyc,
output                      o_s1_wb_stb,
input                       i_s1_wb_ack
);

localparam CPU_REGS_BASE  = 32'h801;

reg     current_master;

wire  current_slave;

wire [31:0]             master_adr;
wire [WB_SWIDTH-1:0]    master_sel;
wire                    master_we;
wire [WB_DWIDTH-1:0]    master_wdat;
wire                    master_cyc;
wire                    master_stb;
wire [WB_DWIDTH-1:0]    master_rdat;
wire                    master_ack;
wire                    master_err;

  always @(posedge i_wb_clk or negedge i_arst_n) begin
    if(!i_arst_n)
      current_master <= 1'b0;
    else if(master_ack)
      current_master <= i_m1_wb_cyc & (~current_master | ~i_m0_wb_cyc);
  end



// Arbitrate between slaves
assign current_slave = in_cpu_regs( master_adr ) ? 1'b1  : 
                                                   1'b0  ;  // default to main memory



assign master_adr   = current_master ? i_m1_wb_adr : i_m0_wb_adr ;
assign master_sel   = current_master ? i_m1_wb_sel : i_m0_wb_sel ;
assign master_wdat  = current_master ? i_m1_wb_dat : i_m0_wb_dat ;
assign master_we    = current_master ? i_m1_wb_we  : i_m0_wb_we  ;
assign master_cyc   = current_master ? i_m1_wb_cyc : i_m0_wb_cyc ;
assign master_stb   = current_master ? i_m1_wb_stb : i_m0_wb_stb ;


// Ethmac Slave outputs
assign o_s0_wb_adr  = master_adr;
assign o_s0_wb_dat  = master_wdat;
assign o_s0_wb_sel  = master_sel;
assign o_s0_wb_we   = current_slave == 1'b0 ? master_we  : 1'd0;
assign o_s0_wb_cyc  = current_slave == 1'b0 ? master_cyc : 1'd0;
assign o_s0_wb_stb  = current_slave == 1'b0 ? master_stb : 1'd0;


// Ethmac Slave outputs
assign o_s1_wb_adr  = master_adr;
assign o_s1_wb_dat  = master_wdat;
assign o_s1_wb_sel  = master_sel;
assign o_s1_wb_we   = current_slave == 1'b1 ? master_we  : 1'd0;
assign o_s1_wb_cyc  = current_slave == 1'b1 ? master_cyc : 1'd0;
assign o_s1_wb_stb  = current_slave == 1'b1 ? master_stb : 1'd0;



// Master Outputs
assign master_rdat  = current_slave == 1'b0  ? i_s0_wb_dat  :
                      current_slave == 1'b1  ? i_s1_wb_dat  :
                                               i_s0_wb_dat  ;


assign master_ack   = current_slave == 1'b0  ? i_s0_wb_ack  :
                      current_slave == 1'b1  ? i_s1_wb_ack  :
                                               i_s0_wb_ack  ; 


  reg [31:0] data_mem1_ff;
  reg [31:0] data_mem2_ff;
  always @(posedge i_wb_clk or negedge i_arst_n) begin
    if(!i_arst_n)
      data_mem1_ff <= 32'h0;
    else if(~current_master)
      data_mem1_ff <= master_rdat;
  end

  assign o_m0_wb_dat = current_master == 1'b1 ? data_mem1_ff : master_rdat;

  always @(posedge i_wb_clk or negedge i_arst_n) begin
    if(!i_arst_n)
      data_mem2_ff <= 32'h0;
    else if(current_master)
      data_mem2_ff <= master_rdat;
  end

  assign o_m1_wb_dat = current_master == 1'b0 ? data_mem2_ff : master_rdat;

// Ethmac Master Outputs
// assign o_m0_wb_dat  = master_rdat;
assign o_m0_wb_ack  = current_master  ? 1'd0 : master_ack;

// Amber Master Outputs
// assign o_m1_wb_dat  = master_rdat;
assign o_m1_wb_ack  = current_master  ? master_ack  : 1'd0;



function in_cpu_regs;
    input [31:0] address;
begin
    in_cpu_regs = address [31:0] == CPU_REGS_BASE;
end
endfunction

endmodule



