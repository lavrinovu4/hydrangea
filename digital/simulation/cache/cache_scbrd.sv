class cache_scbrd;
  integer num_trans = 0;
  integer num_error = 0;
  integer num_check = 0;

  integer cache_num = 0;
  integer mem_num = 0;

  cache_mon cache_mon_v;
  mem_mon   mem_mon_v;

  function new(cache_mon cache_mon_v, mem_mon mem_mon_v);
    this.cache_mon_v = cache_mon_v;
    this.mem_mon_v = mem_mon_v;
  endfunction : new

  function void check_cache_mon(cache_data cache_data_v);
    num_trans++;
    cache_num++;
  endfunction

  function void check_mem_mon(mem_data mem_data_v);
    num_trans++;
    mem_num++;
  endfunction

  task run();
    cache_data data;
    fork
      forever begin
        cache_mon_v.cache_mon_trans.get(data);
        check_cache_mon(data);
      end
      // forever begin
      //   mem_mon_v.wait_data();
      //   check_mem_mon(mem_mon_v.get());
      // end
    join

  endtask : run

  function void print_result();
    $display("Cache scoreboard:");
    $display("num_trans: %d", num_trans);
    $display("num_check: %d", num_check);
    $display("num_error: %d", num_error);
  endfunction : print_result

endclass : cache_scbrd
