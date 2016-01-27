class cache_ro_drv extends  uvm_driver #(cache_ro_transaction);
  `uvm_component_utils(cache_ro_drv)

  uvm_analysis_port #(cache_ro_transaction) item_collected_port;

  protected virtual cache_ro_if cache_ro_if_v;

  cache_ro_transaction cache_ro_trans;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction: new

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    void'(uvm_resource_db#(virtual cache_ro_if)::read_by_name(.scope("ifs"), .name("cache_ro_if"), .val(cache_ro_if_v)));
    cache_ro_trans = new();

    item_collected_port = new("item_collected_port", this);
  endfunction: build_phase

  task run_phase(uvm_phase phase);

    forever begin
      @(posedge cache_ro_if_v.ck);
      seq_item_port.get_next_item(cache_ro_trans);
      item_collected_port.write(cache_ro_trans);

      cache_ro_if_v.cache_addr = cache_ro_trans.cache_addr;
      repeat(cache_ro_trans.delay_between_req) @(posedge cache_ro_if_v.ck);

      cache_ro_if_v.cache_req = 1'b1;
      while(cache_ro_if_v.cache_ack !== 1)
        @(posedge cache_ro_if_v.ck);

      @(posedge cache_ro_if_v.ck);

      cache_ro_if_v.cache_req = 1'b0;
      seq_item_port.item_done();

    end

  endtask : run_phase

endclass : cache_ro_drv
