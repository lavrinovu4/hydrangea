class mem_transaction extends uvm_sequence_item;
  bit  [29:0] mem_addr  = 0 ;
  bit         mem_req  = 0 ;
  rand bit [31:0]   mem_data  ;
  bit          mem_ack   ;
  rand int delay_before_ack;

  constraint mem_bus {
    delay_before_ack <= 8;
  }

  function new(string name = "");
    super.new(name);
  endfunction: new

  `uvm_object_utils_begin(mem_transaction)
    `uvm_field_int(mem_addr, UVM_ALL_ON)
    `uvm_field_int(mem_req, UVM_ALL_ON)
    `uvm_field_int(mem_data, UVM_ALL_ON)
    `uvm_field_int(mem_ack, UVM_ALL_ON)
  `uvm_object_utils_end

endclass : mem_transaction
