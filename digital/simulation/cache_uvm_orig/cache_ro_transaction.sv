class cache_ro_transaction extends uvm_sequence_item;
  rand bit  [29:0]  cache_addr  = 0 ;
  bit               cache_req  = 0 ;
  bit [31:0]        cache_data  ;
  bit               cache_ack   ;
  rand int          delay_between_req;

  constraint ceche_bus {
    delay_between_req > 0;
    delay_between_req <= 8;
    cache_addr > 0;
    cache_addr < 512;
  }

  function new(string name = "");
    super.new(name);
  endfunction: new

  `uvm_object_utils_begin(cache_ro_transaction)
    `uvm_field_int(cache_addr, UVM_ALL_ON)
    `uvm_field_int(cache_req, UVM_ALL_ON)
    `uvm_field_int(cache_data, UVM_ALL_ON)
    `uvm_field_int(cache_ack, UVM_ALL_ON)
    `uvm_field_int(delay_between_req, UVM_ALL_ON)
  `uvm_object_utils_end

endclass : cache_ro_transaction
