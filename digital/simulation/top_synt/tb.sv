`timescale 1us/1ns

module tb;
	reg clk, arst_n;

	parameter PERIOD = 20;              //50MHz

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

  initial begin
    forever begin
      @(leds) $display($time, " -- %h", leds);
    end
  end

  initial begin
    #30;
    arst_n = 0;
    #30 arst_n = 1;
    #150_000;
    if(leds === 'h5003)
      $display("Test SUCCESS");
    else
      $display("Test FAILED");
    $finish;
  end

endmodule
