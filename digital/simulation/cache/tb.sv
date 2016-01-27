
`include "cache_ro_pkg.sv"

module tb ();

  reg           rb;

  cache_ro_int cache_ro_int();

  cache_ro dut(
      /* input ports */
      .i_ck                ( cache_ro_int.ck ),
      .i_rb                ( rb ),
      .i_cache_addr        ( cache_ro_int.cache_addr[29:0] ),
      .i_cache_req         ( cache_ro_int.cache_req ),
      .i_mem_ack           ( cache_ro_int.mem_ack ),
      .i_mem_data          ( cache_ro_int.mem_data[31:0] ),

      /* output ports */
      .o_cache_data        ( cache_ro_int.cache_data[31:0] ),
      .o_cache_ack         ( cache_ro_int.cache_ack ),
      .o_mem_req           ( cache_ro_int.mem_req ),
      .o_mem_addr          ( cache_ro_int.mem_addr[29:0] ));


  initial begin
    cache_ro_int.ck = 1'b0;
    forever #10 cache_ro_int.ck = ~cache_ro_int.ck;
  end

  initial begin
    rb = 1'b0;
    #20 rb = 1'b1;

    cache_ro_pkg::run_test(cache_ro_int);
  end

endmodule
