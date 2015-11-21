`timescale 1us/1ns

`define PATH_MEM u_dut.mem.u_mem.mem

module tb;
  reg clk, arst_n;

  parameter PERIOD = 20;              //50MHz
  parameter N_TEST = 1;               //number of tests
  parameter EXPIRED_NUMBER_CLK = 20000; //max time for one test

  parameter ADDR_VALID_TRUE = 320;      //address of flag valid data inside memory of data
  parameter ADDR_RECEIVED_DATA = 321;   //addres where test save data result

  localparam NAME_WIDTH = 16;
  reg [8*NAME_WIDTH : 0] name_test [N_TEST - 1 : 0];
  reg [31 : 0] data_expected [N_TEST - 1 : 0];
  reg [31 : 0] value;

  integer i, end_test;

  wire [15:0] leds;

  //the highest module of mips
  top u_dut(
    .i_clk      (clk),
    .i_arst_n   (arst_n),
    .o_leds     (leds));

  //generate clock
  initial begin
    clk = 0;
    forever clk = #(PERIOD/2) ~clk;
  end


  //generate input data
  initial begin
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
      @(posedge (end_test === 1));
      value = `PATH_MEM[ADDR_RECEIVED_DATA];
      if(value === data_expected[i])
        $display("----------------- \nTEST SUCCESS\n----------------- \n");
      else
        $display("----------------- \nError!! TEST FAILED\n----------------- \n");
    end
  end
/*
  initial begin
    $dumpfile("wave.vcd");
    $dumpvars(5);
  end
*/
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
      $display("\n\nerror: Out of time");
      $finish;
    end
    `PATH_MEM[ADDR_VALID_TRUE] = 0;
  end
  endtask

  //test data for mips
  initial begin
    name_test[0] = "program.dat"; data_expected[0] = 21;
  end

endmodule
