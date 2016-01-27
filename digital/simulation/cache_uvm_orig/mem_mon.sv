class mem_mon extends  uvm_monitor;

  `uvm_component_utils(mem_mon)

  protected virtual cache_ro_if cache_ro_if_v;

  uvm_analysis_port #(mem_transaction) item_collected_port;
  mem_transaction mem_trans;

  bit [29:0] pre_addr;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction: new

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    void'(uvm_resource_db#(virtual cache_ro_if)::read_by_name(.scope("ifs"), .name("cache_ro_if"), .val(cache_ro_if_v)));
    item_collected_port = new("item_collected_port", this);
    mem_trans = new();
  endfunction: build_phase

  task run_phase(uvm_phase phase);
    forever @(posedge cache_ro_if_v.ck) begin
      if(/*cache_ro_if_v.mem_req &&*/ cache_ro_if_v.mem_ack) begin
        mem_trans.mem_addr = pre_addr;
        item_collected_port.write(mem_trans);
      end
      pre_addr = cache_ro_if_v.mem_addr;
    end
  endtask

endclass : mem_mon
