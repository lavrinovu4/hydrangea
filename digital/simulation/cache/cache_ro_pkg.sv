`ifndef __CACHE_RO_PKG__
`define __CACHE_RO_PKG__

`timescale 1ns/10ps

`include "cache_ro_int.sv"
`include "global_def.sv"

package cache_ro_pkg;

`include "transmittion.sv"

`include "cache_data.sv"
`include "mem_data.sv"

`include "cache_mon.sv"
`include "mem_mon.sv"

`include "cache_drv.sv"
`include "mem_drv.sv"

`include "cache_scbrd.sv"

`include "cache_env.sv"

`include "testcase.sv"

testcase testcase_v;

task run_test(virtual cache_ro_int reg_if);
  testcase_v = new(reg_if);
  testcase_v.run_test();
endtask

endpackage

`endif //!__CACHE_RO_PKG__
