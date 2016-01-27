class testcase;
  cache_env cache_env_v;

  function new(virtual cache_ro_int dut_int);
    cache_env_v = new(dut_int);

  endfunction : new


  task run;
    cache_env_v.mem_drv_v.mem_drv_en = 1;
    cache_env_v.cache_drv_v.cache_drv_en = 1;
    fork
      begin
        forever
    cache_env_v.mem_drv_v.ack_data(3);
      end

      begin
    cache_env_v.cache_drv_v.req_addr(1);
    cache_env_v.cache_drv_v.req_addr(2);
    #`US;
      end
    join_any
    cache_env_v.cache_scbrd_v.print_result();
    #10 $finish;
  endtask

  task run_test();
    fork
    cache_env_v.run();
    run();
    join_any
  endtask : run_test

endclass : testcase
