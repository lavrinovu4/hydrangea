`include "cache_ro_pkg.sv"

module tb();
  import cache_ro_pkg::*;

  logic rb;
  cache_ro_if cache_ro_if_v();

  cache_ro dut(
      /* input ports */
      .i_ck                ( cache_ro_if_v.ck ),
      .i_rb                ( rb ),
      .i_cache_addr        ( cache_ro_if_v.cache_addr[29:0] ),
      .i_cache_req         ( cache_ro_if_v.cache_req ),
      .i_mem_ack           ( cache_ro_if_v.mem_ack ),
      .i_mem_data          ( cache_ro_if_v.mem_data[31:0] ),

      /* output ports */
      .o_cache_data        ( cache_ro_if_v.cache_data[31:0] ),
      .o_cache_ack         ( cache_ro_if_v.cache_ack ),
      .o_mem_req           ( cache_ro_if_v.mem_req ),
      .o_mem_addr          ( cache_ro_if_v.mem_addr[29:0] ));


  // Clock generation
  initial begin
    cache_ro_if_v.ck = 1'b0;
    forever #10 cache_ro_if_v.ck = ~cache_ro_if_v.ck;
  end

  // Reset generation
  initial begin
    rb = 1'b0;
    @(posedge cache_ro_if_v.ck);
    rb = 1'b1;
  end

  initial begin

    //Registers the Interface in the configuration block so that other
    //blocks can use it
    uvm_pkg::uvm_resource_db#(virtual cache_ro_if )::set(.scope("ifs"), .name("cache_ro_if"), .val(cache_ro_if_v));

    //Executes the test
    uvm_pkg::run_test();
  end


endmodule
