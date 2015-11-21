
module top_2cores(i_clk, i_arst_n, i_int_source,
          
            o_wb_cyc, o_wb_stb, o_wb_sel, o_wb_we, o_wb_adr, o_wb_dat,
            i_wb_dat, i_wb_ack  );

  parameter N_INTS            = 10;

  //-----------------------------------
  input                   i_clk;
  input                   i_arst_n;

  input [N_INTS - 1 : 0]  i_int_source;

  //wishbone-------------------
  input               i_wb_ack;
  input [31 : 0]      i_wb_dat;
  output              o_wb_cyc;
  output              o_wb_stb;
  output              o_wb_we;
  output [3 : 0]      o_wb_sel;
  output [31 : 0]     o_wb_adr;
  output [31 : 0]     o_wb_dat;


  localparam WB_MASTERS = 2;
  localparam WB_SWIDTH = 4;
  localparam WB_DWIDTH = 32;

    // Wishbone Master Buses
    wire      [31:0]            m_wb_adr      [WB_MASTERS-1:0];
    wire      [WB_SWIDTH-1:0]   m_wb_sel      [WB_MASTERS-1:0];
    wire      [WB_MASTERS-1:0]  m_wb_we                       ;
    wire      [WB_DWIDTH-1:0]   m_wb_dat_w    [WB_MASTERS-1:0];
    wire      [WB_DWIDTH-1:0]   m_wb_dat_r    [WB_MASTERS-1:0];
    wire      [WB_MASTERS-1:0]  m_wb_cyc                      ;
    wire      [WB_MASTERS-1:0]  m_wb_stb                      ;
    wire      [WB_MASTERS-1:0]  m_wb_ack                      ;
    


    // Wishbone Slave Buses
    wire      [31:0]            cpu_reg_wb_adr;
    wire      [WB_SWIDTH-1:0]   cpu_reg_wb_sel;
    wire                        cpu_reg_wb_we;
    wire      [WB_DWIDTH-1:0]   cpu_reg_wb_dat_w;
    wire      [WB_DWIDTH-1:0]   cpu_reg_wb_dat_r;
    wire                        cpu_reg_wb_cyc;
    wire                        cpu_reg_wb_stb;
    wire                        cpu_reg_wb_ack;


    wire [31:0] cpu_regs;


  //the highest module of mips
  core #(
    .PC_START_ADDRRES (29'h0),
    .N_INTS           (5))
   u_core0(
    .i_clk        ( i_clk     ),
    .i_arst_n     ( i_arst_n  ),
    .i_core_en    ( cpu_regs[0] ),
    .i_int_source ( i_int_source[4:0]   ),

    .o_wb_cyc     ( m_wb_cyc  [0] ),
    .o_wb_stb     ( m_wb_stb  [0] ),
    .o_wb_sel     ( m_wb_sel  [0] ),
    .o_wb_we      ( m_wb_we   [0] ),
    .o_wb_adr     ( m_wb_adr  [0] ),
    .o_wb_dat     ( m_wb_dat_w[0] ),
    .i_wb_dat     ( m_wb_dat_r[0] ),
    .i_wb_ack     ( m_wb_ack  [0] ));


  //the highest module of mips
  core #(
    .PC_START_ADDRRES (29'h0),
    .N_INTS           (5))
   u_core1(
    .i_clk        ( i_clk           ),
    .i_arst_n     ( i_arst_n        ),
    .i_core_en    ( cpu_regs[1]     ),
    .i_int_source (  i_int_source[9:5]   ),

    .o_wb_cyc     ( m_wb_cyc  [1] ),
    .o_wb_stb     ( m_wb_stb  [1] ),
    .o_wb_sel     ( m_wb_sel  [1] ),
    .o_wb_we      ( m_wb_we   [1] ),
    .o_wb_adr     ( m_wb_adr  [1] ),
    .o_wb_dat     ( m_wb_dat_w[1] ),
    .i_wb_dat     ( m_wb_dat_r[1] ),
    .i_wb_ack     ( m_wb_ack  [1] ));


    cpu_regs  u_cpu_regs(     
                            .i_ck(i_clk),
                            .i_rb(i_arst_n),

                            
                            .i_wb_adr( cpu_reg_wb_adr),
                            .i_wb_sel(cpu_reg_wb_sel),
                            .i_wb_we(cpu_reg_wb_we ),
                            .i_wb_dat(cpu_reg_wb_dat_w),
                            .o_wb_dat(cpu_reg_wb_dat_r),
                            .i_wb_cyc(cpu_reg_wb_cyc),
                            .i_wb_stb(cpu_reg_wb_stb),
                            .o_wb_ack(cpu_reg_wb_ack),

                            .o_cpu_regs  (cpu_regs)
                                        );

  bus_ctrl #(
    .WB_DWIDTH              ( WB_DWIDTH         ),
    .WB_SWIDTH              ( WB_SWIDTH         ))
   u_bus_ctrl (
    .i_wb_clk               ( i_clk           ),
    .i_arst_n               ( i_arst_n  ),

    // WISHBONE master 0 - Ethmac
    .i_m0_wb_adr            (  m_wb_adr   [0]   ),
    .i_m0_wb_sel            (  m_wb_sel   [0]   ),
    .i_m0_wb_we             (  m_wb_we    [0]   ),
    .o_m0_wb_dat            (  m_wb_dat_r [0]   ),
    .i_m0_wb_dat            (  m_wb_dat_w [0]   ),
    .i_m0_wb_cyc            (  m_wb_cyc   [0]   ),
    .i_m0_wb_stb            (  m_wb_stb   [0]   ),
    .o_m0_wb_ack            (  m_wb_ack   [0]   ),


    // WISHBONE master 1 - Amber Process or
    .i_m1_wb_adr            ( m_wb_adr   [1]    ),
    .i_m1_wb_sel            ( m_wb_sel   [1]    ),
    .i_m1_wb_we             ( m_wb_we    [1]    ),
    .o_m1_wb_dat            ( m_wb_dat_r [1]    ),
    .i_m1_wb_dat            ( m_wb_dat_w [1]    ),
    .i_m1_wb_cyc            ( m_wb_cyc   [1]    ),
    .i_m1_wb_stb            ( m_wb_stb   [1]    ),
    .o_m1_wb_ack            ( m_wb_ack   [1]    ),

    .o_s0_wb_adr            ( o_wb_adr      ),
    .o_s0_wb_sel            ( o_wb_sel      ),
    .o_s0_wb_we             ( o_wb_we       ),
    .i_s0_wb_dat            ( i_wb_dat      ),
    .o_s0_wb_dat            ( o_wb_dat      ),
    .o_s0_wb_cyc            ( o_wb_cyc      ),
    .o_s0_wb_stb            ( o_wb_stb      ),
    .i_s0_wb_ack            ( i_wb_ack      ),


    .o_s1_wb_adr            ( cpu_reg_wb_adr      ),
    .o_s1_wb_sel            ( cpu_reg_wb_sel      ),
    .o_s1_wb_we             ( cpu_reg_wb_we       ),
    .i_s1_wb_dat            ( cpu_reg_wb_dat_r      ),
    .o_s1_wb_dat            ( cpu_reg_wb_dat_w      ),
    .o_s1_wb_cyc            ( cpu_reg_wb_cyc      ),
    .o_s1_wb_stb            ( cpu_reg_wb_stb      ),
    .i_s1_wb_ack            ( cpu_reg_wb_ack      ));

endmodule