class cache_ro_mon extends  uvm_monitor;

  `uvm_component_utils(cache_ro_mon)

  protected virtual cache_ro_if cache_ro_if_v;

  uvm_analysis_port #(cache_ro_transaction) item_collected_port;
  cache_ro_transaction cache_ro_trans;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction: new

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    void'(uvm_resource_db#(virtual cache_ro_if)::read_by_name(.scope("ifs"), .name("cache_ro_if"), .val(cache_ro_if_v)));
    item_collected_port = new("item_collected_port", this);
    cache_ro_trans = new();
  endfunction: build_phase

  task run_phase(uvm_phase phase);
    forever @(posedge cache_ro_if_v.cache_ack) begin
      @(posedge cache_ro_if_v.ck); //wait period to catch the newest data
      if(cache_ro_if_v.cache_ack === 1) begin  // not include x values
        cache_ro_trans.cache_data = cache_ro_if_v.cache_data;
        item_collected_port.write(cache_ro_trans);
      end
    end
  endtask

endclass : cache_ro_mon
