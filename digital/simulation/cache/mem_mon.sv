
class mem_mon extends  transmittion #(.data_type(mem_data));
  virtual cache_ro_int cache_ro_int_v;
  mem_data mem_data_v;

  function new(virtual cache_ro_int cache_ro_int_v);
    this.cache_ro_int_v = cache_ro_int_v;
    mem_data_v = new();
  endfunction : new

  task run();
    forever @(posedge cache_ro_int_v.ck) begin
      if(cache_ro_int_v.mem_req && cache_ro_int_v.mem_ack) begin
        mem_data_v.mem_addr = cache_ro_int_v.mem_addr;
        send(mem_data_v);
      end
    end
  endtask : run

endclass : mem_mon
