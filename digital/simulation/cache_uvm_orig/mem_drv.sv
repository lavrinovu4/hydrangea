class mem_drv extends  uvm_driver #(mem_transaction);
  `uvm_component_utils(mem_drv)

  virtual cache_ro_if cache_ro_if_v;

  uvm_analysis_port #(mem_transaction) item_collected_port;

  mem_transaction mem_trans;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction : new

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    void'(uvm_resource_db#(virtual cache_ro_if)::read_by_name(.scope("ifs"), .name("cache_ro_if"), .val(cache_ro_if_v)));

    item_collected_port = new("item_collected_port", this);

    mem_trans = new();
  endfunction : build_phase


  task run_phase(uvm_phase phase);

    forever @(posedge cache_ro_if_v.ck) begin

        if(cache_ro_if_v.mem_req) begin

          if(!cache_ro_if_v.memory[cache_ro_if_v.mem_addr]) begin
            void'(mem_trans.randomize());
            cache_ro_if_v.memory[cache_ro_if_v.mem_addr] = mem_trans.mem_data;
          end

          cache_ro_if_v.mem_data = mem_trans.mem_data;
          repeat(mem_trans.delay_before_ack) @(posedge cache_ro_if_v.ck);
          cache_ro_if_v.mem_ack = 1'b1;
          @(posedge cache_ro_if_v.ck)
          item_collected_port.write(mem_trans);
          cache_ro_if_v.mem_ack = 1'b0;
        end
    end

  endtask : run_phase

endclass : mem_drv
