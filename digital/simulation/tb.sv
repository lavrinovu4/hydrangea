`timescale 1us/1ns

`define BOOT_FILE

module tb;
	reg clk, arst_n, ext_int;

	parameter PERIOD = 20;
  parameter N_TEST = 8;               //number of tests  
  parameter ADDR_VALID_TRUE = 1;      //address of valid data inside memory of data - if you change them
                                      //you need chenge this addres in your test file
  parameter ADDR_RECEIVED_DATA = 2;   //addres where test save data result

  localparam NAME_WIDTH = 12;
  reg [8*NAME_WIDTH : 0] name_test [N_TEST - 1 : 0];
  reg [31 : 0] data_expected [N_TEST - 1 : 0];
  reg [31 : 0] value;

  integer i, end_test; 

  wire []  

  wire                    mips_wb_we;
  wire [3:0]              mips_wb_sel;
  wire [31:0]             mips_wb_adr;
  wire [31:0]             mips_wb_dat_i;
  wire                    mips_wb_cyc;
  wire                    mips_wb_stb;
  wire [31:0]             mips_wb_dat_o;
  wire                    mips_wb_ack;

  wire [31 : 0]             instruction;
  wire [29 : 0]             adr_instruction; 

  instr_mem u_instr_mem(
    .i_address      ( {2'b00, adr_instruction} ),
    .o_instruction  ( instruction              )
  );

  wb_slave_test u_wb_slave  (     
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

  core #(
    .N_INTS       ( 1 ))
   u_mips_core (
    .i_clk        (clk), 
    .i_arst_n     (arst_n ), 
    .i_int_source (ext_int),

    .i_instr_mem  ( instruction     ),
    .o_instr_adr  ( adr_instruction ),
    
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

  //the highest module of mips
	core u_core(
		.i_clk				( clk 		),
		.i_arst_n			( arst_n 	),
    .i_ext_int    ( ext_int ));

  //check coorect signal inside mips
  checking u_checking(
    .i_clk        (clk), 
    .i_arst_n     (arst_n),
    .i(i));

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
      @(posedge end_test);
      value = u_core.u_mem_access.u_data_mem.mem_data[ADDR_RECEIVED_DATA];
      if(value == data_expected[i - 1])
      	$display("----------------- TEST SUCCESS\n");
		  else
			  $display("----------------- TEST FAILED\n");
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
    $readmemh(name, u_core.u_fetch.u_instr_mem.mem);
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

    await_count = 600;
    end_test = u_core.u_mem_access.u_data_mem.mem_data[ADDR_VALID_TRUE];
    while((1 !== end_test) && (0 != await_count)) begin
      await_count--;
      @(negedge clk);
      end_test = u_core.u_mem_access.u_data_mem.mem_data[ADDR_VALID_TRUE];
    end
    if(!await_count)
      $display("error: Out of time");
    u_core.u_mem_access.u_data_mem.mem_data[ADDR_VALID_TRUE] = 0;
  end
  endtask

  //external inerrupt generation
  initial begin
    repeat(10) @(posedge clk);
    forever begin
      repeat(5) @(posedge clk);
      if(i == 6) begin
        repeat(18) @(posedge clk);
          ext_int = ~ext_int;
        end
    end
  end

  //test data for mips
  initial begin
    name_test[0] = "t0.dat"; data_expected[0] = 21;       //addi, add, beq, sw 
    name_test[1] = "t1.dat"; data_expected[1] = 2;        //immediate instructions, hazards, negative numbers
    name_test[2] = "t2.dat"; data_expected[2] = 7;        //add, sub, and, or, slt, addi, lw, sw, beq, j
    name_test[3] = "t3.dat"; data_expected[3] = 0;        //coprocessor
    name_test[4] = "t4.dat"; data_expected[4] = 1;        //Overflow exception test
    name_test[5] = "t5.dat"; data_expected[5] = 'h3f8;    //all shift
    name_test[6] = "t6.dat"; data_expected[6] = 'h10;     //external interrupt
    name_test[7] = "t7.dat"; data_expected[7] = 1;        //wrong instruction exeption
  end

endmodule
