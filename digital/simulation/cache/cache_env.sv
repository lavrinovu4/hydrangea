class cache_env;
  cache_drv cache_drv_v;
  cache_mon cache_mon_v;
  mem_drv   mem_drv_v;
  mem_mon   mem_mon_v;
  cache_scbrd cache_scbrd_v;

  function new(virtual cache_ro_int dut_int);
    cache_drv_v = new(dut_int);
    cache_mon_v = new(dut_int);

    mem_drv_v = new(dut_int);
    mem_mon_v = new(dut_int);

    cache_scbrd_v = new(cache_mon_v, mem_mon_v);

  endfunction : new

  task run();
    fork
      cache_drv_v.run();
      mem_drv_v.run();
      cache_mon_v.run();
      mem_mon_v.run();
      cache_scbrd_v.run();
    join
  endtask

endclass : cache_env
