`timescale 1us/1ns

`define BOOT_FILE

`define PATH_MEM mem.u_mem.mem

module tb;
  reg clk, arst_n;
  reg [8:0] ext_int;

  parameter PERIOD = 20;
  parameter N_TEST = 8;               //number of tests

  parameter EXPIRED_NUMBER_CLK = 600;

  parameter ADDR_VALID_TRUE = 320;      //address of flag valid data inside memory of data
  parameter ADDR_RECEIVED_DATA = 321;   //addres where test save data result

  localparam NAME_WIDTH = 16;

  reg [8*NAME_WIDTH : 0] name_test [N_TEST - 1 : 0];
  reg [31 : 0] data_expected [N_TEST - 1 : 0];
  reg [31 : 0] value;

  integer i, end_test;

  wire                    mips_wb_we;
  wire [3:0]              mips_wb_sel;
  wire [31:0]             mips_wb_adr;
  wire [31:0]             mips_wb_dat_i;
  wire                    mips_wb_cyc;
  wire                    mips_wb_stb;
  wire [31:0]             mips_wb_dat_o;
  wire                    mips_wb_ack;


  //the highest module of mips
  core #(
    .N_INTS       ( 9 ))
   u_core (
    .i_clk        (clk),
    .i_arst_n     (arst_n ),
    .i_core_en    ( 1'b1 ),
    .i_int_source (ext_int),

    //Wishbone interface
    .i_wb_dat     (mips_wb_dat_i),
    .i_wb_ack     (mips_wb_ack),
    .o_wb_we      (mips_wb_we),
    .o_wb_sel     (mips_wb_sel),
    .o_wb_adr     (mips_wb_adr),
    .o_wb_dat     (mips_wb_dat_o),
    .o_wb_cyc     (mips_wb_cyc),
    .o_wb_stb     (mips_wb_stb)
  );

  wb_slave_test mem (
    .i_ck         (clk),
    .i_rb         (arst_n),

    .i_wb_we      (mips_wb_we),
    .i_wb_sel     (mips_wb_sel),
    .i_wb_adr     (mips_wb_adr),
    .i_wb_dat     (mips_wb_dat_o),
    .i_wb_cyc     (mips_wb_cyc),
    .i_wb_stb     (mips_wb_stb),
    .o_wb_dat     (mips_wb_dat_i),
    .o_wb_ack     (mips_wb_ack)
  );

  //check coorect signal inside mips
  checking u_checking(
    .i_clk        (clk),
    .i_arst_n     (arst_n),
    .i(i)
  );

  //generate clock
  initial begin
    clk = 0;
    forever clk = #(PERIOD/2) ~clk;
  end


  //generate input data
  initial begin
    ext_int = 0;
    @(negedge clk);

    for(i = 0; i < N_TEST; i++) begin
      test_launch(name_test[i]);
    end

    @(negedge clk);
    $finish;
  end

  //check correct work of mips
  initial begin
    forever begin
      @(posedge (end_test == 1));
      value = `PATH_MEM[ADDR_RECEIVED_DATA];
      if(value == data_expected[i])
        $display("----------------- \nTEST SUCCESS\n----------------- \n");
      else
        $display("----------------- \nError!! TEST FAILED\n----------------- \n");
    end
  end

  initial begin
    $dumpfile("wave.vcd");
    $dumpvars(5);
  end

  task load_test;
    input [8*NAME_WIDTH : 0] name;
  begin
    $display(" Loading %s", name);
    $readmemh(name, `PATH_MEM);
  end
  endtask

  task test_launch;
    input [8*NAME_WIDTH : 0] name;
    integer await_count;
  begin
    @(negedge clk);
    arst_n = 0;
    load_test(name);
    @(negedge clk) arst_n = 1;

    await_count = EXPIRED_NUMBER_CLK;
    end_test = `PATH_MEM[ADDR_VALID_TRUE];
    while((1 !== end_test) && (0 != await_count)) begin
      await_count--;
      @(negedge clk);
      end_test = `PATH_MEM[ADDR_VALID_TRUE];
    end
    if(!await_count) begin
      $display("error: Out of time");
      $finish;
    end
    @(negedge mips_wb_ack);
    `PATH_MEM[ADDR_VALID_TRUE] = 0;
  end
  endtask

  //test data for mips
  initial begin
    name_test[0] = "t0.dat"; data_expected[0] = 21;                             //addi, add, beq, sw
    name_test[1] = "t1.dat"; data_expected[1] = 2;                              //immediate instructions, hazards, negative numbers
    name_test[2] = "t2.dat"; data_expected[2] = 7;                              //add, sub, and, or, slt, addi, lw, sw, beq, j
    name_test[3] = "t3.dat"; data_expected[3] = 'h3f8;                          //all shift
    name_test[4] = "t4.dat"; data_expected[4] = 2;                              //bgez, bgezal, bgtz, blez, bltz, bltzal
    name_test[5] = "t5.dat"; data_expected[5] = 32'h12000000 + 32'h12345678 +
                                                32'h12340000 + 32'h12345678 +
                                                32'h12345600 + 32'h12345678 +
                                                32'h12345678 + 32'h11111111 + //lwl, lwr, swl, swr

                                                32'h90 + 32'hffffff90 +         //lb, lbu, sb, sbu
                                                32'h8072 + 32'hffff8072 + //lh, lhu, sh
                                                32'h0fff + 32'h0fff;    //lw, sw

    name_test[6] = "t6.dat"; data_expected[6] = 130;          //mult,div,mfhi,mflo
    name_test[7] = "t7.dat"; data_expected[7] = 32474 + 8;        //interrupts and exceptions
  end

  wire [31 : 0] pc;
  assign pc = u_core.pc_de << 2;

  initial begin
    @(i === 7);
    @(pc === 32'ha0);

    ext_int = 9'h1;

    #230 ext_int = ext_int << 1;
    #130 ext_int = ext_int << 1;
    #530 ext_int = ext_int << 1;
    #200 ext_int = ext_int << 1;
    #291 ext_int = ext_int << 1; //TODO: strange strange behavior of simulator(interrupts and clk)
    #930 ext_int = ext_int << 1;
    #70 ext_int = ext_int << 1;
    #340 ext_int = ext_int << 1;
    #730 ext_int = ext_int << 1;
  end

endmodule