
class mem_data;

  bit  [29:0] mem_addr  ;
  bit         mem_req   ;
  bit [31:0]   mem_data = 0 ;
  bit          mem_ack  = 0 ;

endclass : mem_data
