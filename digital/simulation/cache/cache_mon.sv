
class cache_mon;
  transmittion #(cache_data) cache_mon_trans;
  virtual cache_ro_int cache_ro_int_v;
  cache_data cache_data_v;

  function new(virtual cache_ro_int cache_ro_int_v);
    this.cache_ro_int_v = cache_ro_int_v;
    cache_data_v = new();
    cache_mon_trans = new();
  endfunction : new

  task run();
    forever @(posedge cache_ro_int_v.cache_ack) begin
      if(cache_ro_int_v.cache_ack === 1) begin
        cache_data_v.cache_data = cache_ro_int_v.cache_data;
        cache_mon_trans.send(cache_data_v);
      end
    end
  endtask : run

endclass : cache_mon
