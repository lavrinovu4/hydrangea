module top (i_clk, i_arst_n, o_leds);
    input i_clk;
    input i_arst_n;

    output [15:0] o_leds;

  wire [31:0] mleds;
  wire [9:0] ext_int;

  assign ext_int = 0;


localparam WB_MASTERS = 1;
localparam WB_SLAVES  = 2;
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
    wire      [31:0]            s_wb_adr      [WB_SLAVES-1:0];
    wire      [WB_SWIDTH-1:0]   s_wb_sel      [WB_SLAVES-1:0];
    wire      [WB_SLAVES-1:0]   s_wb_we                      ;
    wire      [WB_DWIDTH-1:0]   s_wb_dat_w    [WB_SLAVES-1:0];
    wire      [WB_DWIDTH-1:0]   s_wb_dat_r    [WB_SLAVES-1:0];
    wire      [WB_SLAVES-1:0]   s_wb_cyc                     ;
    wire      [WB_SLAVES-1:0]   s_wb_stb                     ;
    wire      [WB_SLAVES-1:0]   s_wb_ack                     ;


  //the highest module of mips
  core u_core(
    .i_clk        ( i_clk     ),
    .i_arst_n     ( i_arst_n  ),
    .i_core_en    ( 1'b1 ),
    .i_int_source ( ext_int   ),

    .o_wb_cyc     ( m_wb_cyc  [0] ),
    .o_wb_stb     ( m_wb_stb  [0] ),
    .o_wb_sel     ( m_wb_sel  [0] ),
    .o_wb_we      ( m_wb_we   [0] ),
    .o_wb_adr     ( m_wb_adr  [0] ),
    .o_wb_dat     ( m_wb_dat_w[0] ),
    .i_wb_dat     ( m_wb_dat_r[0] ),
    .i_wb_ack     ( m_wb_ack  [0] ));


  memory_wb  mem(
                            .i_ck(i_clk),
                            .i_rb(i_arst_n),

                            .i_wb_we(s_wb_we   [0] ),
                            .i_wb_sel(s_wb_sel  [0] ),
                            .i_wb_adr(s_wb_adr  [0] ),
                            .i_wb_dat(s_wb_dat_w[0] ),
                            .i_wb_cyc(s_wb_cyc  [0] ),
                            .i_wb_stb(s_wb_stb  [0] ),
                            .o_wb_dat(s_wb_dat_r[0] ),
                            .o_wb_ack(s_wb_ack  [0] )
                                        );


  leds  u_leds(
                            .i_ck(i_clk),
                            .i_rb(i_arst_n),


                            .i_wb_we(s_wb_we   [1]),
                            .i_wb_sel(s_wb_sel  [1]),
                            .i_wb_adr(s_wb_adr  [1]),
                            .i_wb_dat(s_wb_dat_w[1]),
                            .i_wb_cyc(s_wb_cyc  [1]),
                            .i_wb_stb(s_wb_stb  [1]),
                            .o_wb_dat(s_wb_dat_r[1]),
                            .o_wb_ack(s_wb_ack  [1]),

                            .o_leds  (mleds)
                                        );

    assign o_leds = mleds[15:0];

// -------------------------------------------------------------
// Instantiate Wishbone Arbiter
// -------------------------------------------------------------
wishbone_arbiter #(
    .WB_DWIDTH              ( WB_DWIDTH         ),
    .WB_SWIDTH              ( WB_SWIDTH         )
    )
u_wishbone_arbiter (
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
    .o_m0_wb_err            (     ),


    // WISHBONE master 1 - Amber Process or
    .i_m1_wb_adr            (  0  ),
    .i_m1_wb_sel            (  4'h0  ),
    .i_m1_wb_we             (  1'b0  ),
    .o_m1_wb_dat            (    ),
    .i_m1_wb_dat            (  0  ),
    .i_m1_wb_cyc            (  1'b0  ),
    .i_m1_wb_stb            (  1'b0  ),
    .o_m1_wb_ack            (    ),
    .o_m1_wb_err            (    ),


    // WISHBONE slave 0 - Ethmac
    .o_s0_wb_adr            ( s_wb_adr   [0]    ),
    .o_s0_wb_sel            ( s_wb_sel   [0]    ),
    .o_s0_wb_we             ( s_wb_we    [0]    ),
    .i_s0_wb_dat            ( s_wb_dat_r [0]    ),
    .o_s0_wb_dat            ( s_wb_dat_w [0]    ),
    .o_s0_wb_cyc            ( s_wb_cyc   [0]    ),
    .o_s0_wb_stb            ( s_wb_stb   [0]    ),
    .i_s0_wb_ack            ( s_wb_ack   [0]    ),
    .i_s0_wb_err            ( 1'b0    ),


    // WISHBONE slave 1 - Boot Memory
    .o_s1_wb_adr            ( s_wb_adr   [1]    ),
    .o_s1_wb_sel            ( s_wb_sel   [1]    ),
    .o_s1_wb_we             ( s_wb_we    [1]    ),
    .i_s1_wb_dat            ( s_wb_dat_r [1]    ),
    .o_s1_wb_dat            ( s_wb_dat_w [1]    ),
    .o_s1_wb_cyc            ( s_wb_cyc   [1]    ),
    .o_s1_wb_stb            ( s_wb_stb   [1]    ),
    .i_s1_wb_ack            ( s_wb_ack   [1]    ),
    .i_s1_wb_err            ( 1'b0    ),


    // WISHBONE slave 2 - Main Memory
    .o_s2_wb_adr            (     ),
    .o_s2_wb_sel            (     ),
    .o_s2_wb_we             (     ),
    .i_s2_wb_dat            ( 0    ),
    .o_s2_wb_dat            (     ),
    .o_s2_wb_cyc            (     ),
    .o_s2_wb_stb            (     ),
    .i_s2_wb_ack            ( 1'b0    ),
    .i_s2_wb_err            ( 1'b0    ),


    // WISHBONE slave 3 - UART 0
    .o_s3_wb_adr            (     ),
    .o_s3_wb_sel            (     ),
    .o_s3_wb_we             (     ),
    .i_s3_wb_dat            (  0   ),
    .o_s3_wb_dat            (     ),
    .o_s3_wb_cyc            (     ),
    .o_s3_wb_stb            (     ),
    .i_s3_wb_ack            (  1'b0   ),
    .i_s3_wb_err            (  1'b0   ),


    // WISHBONE slave 4 - UART 1
    .o_s4_wb_adr            (     ),
    .o_s4_wb_sel            (     ),
    .o_s4_wb_we             (     ),
    .i_s4_wb_dat            (  0   ),
    .o_s4_wb_dat            (     ),
    .o_s4_wb_cyc            (     ),
    .o_s4_wb_stb            (     ),
    .i_s4_wb_ack            (  1'b0   ),
    .i_s4_wb_err            (  1'b0   ),


    // WISHBONE slave 5 - Test Module
    .o_s5_wb_adr            (     ),
    .o_s5_wb_sel            (     ),
    .o_s5_wb_we             (     ),
    .i_s5_wb_dat            (  0   ),
    .o_s5_wb_dat            (     ),
    .o_s5_wb_cyc            (     ),
    .o_s5_wb_stb            (     ),
    .i_s5_wb_ack            (  1'b0   ),
    .i_s5_wb_err            (  1'b0   ),


    // WISHBONE slave 6 - Timer Module
    .o_s6_wb_adr            (     ),
    .o_s6_wb_sel            (     ),
    .o_s6_wb_we             (     ),
    .i_s6_wb_dat            (  0   ),
    .o_s6_wb_dat            (     ),
    .o_s6_wb_cyc            (     ),
    .o_s6_wb_stb            (     ),
    .i_s6_wb_ack            (  1'b0   ),
    .i_s6_wb_err            (  1'b0   ),


    // WISHBONE slave 7 - Interrupt Controller
    .o_s7_wb_adr            (     ),
    .o_s7_wb_sel            (     ),
    .o_s7_wb_we             (     ),
    .i_s7_wb_dat            (  0   ),
    .o_s7_wb_dat            (     ),
    .o_s7_wb_cyc            (     ),
    .o_s7_wb_stb            (     ),
    .i_s7_wb_ack            (  1'b0   ),
    .i_s7_wb_err            (  1'b0   )
    );

endmodule
