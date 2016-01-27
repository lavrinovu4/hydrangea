`ifndef __CACHE_RO_INIT__
`define __CACHE_RO_INIT__

interface cache_ro_int();
  logic         ck;

  logic [29:0] cache_addr  ;
  logic        cache_req   ;
  logic [31:0] cache_data  ;
  logic        cache_ack   ;

  logic        mem_ack     ;
  logic [31:0] mem_data    ;
  logic        mem_req     ;
  logic [29:0] mem_addr    ;

endinterface

`endif  //!__CACHE_RO_INIT__
