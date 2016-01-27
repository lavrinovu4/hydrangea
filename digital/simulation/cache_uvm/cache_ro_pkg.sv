
`include "cache_ro_if.sv"
`include "uvm_macros.svh"

package cache_ro_pkg;

  import uvm_pkg::*;


  `include "cache_ro_transaction.sv"
  `include "mem_transaction.sv"

  `include "cache_ro_drv.sv"
  `include "mem_drv.sv"

  `include "cache_ro_mon.sv"
  `include "mem_mon.sv"

  `include "global_scoreboard.sv"

  `include "cache_ro_sq.sv"

  `include "cache_ro_env.sv"

  `include "default_testcase.sv"

endpackage
