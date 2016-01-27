
class cache_drv extends  transmittion #(.data_type(cache_data));
  integer cache_drv_en = 0;
  virtual cache_ro_int cache_ro_int_v;
  cache_data cache_data_v;
  integer status_loaded = 0;

  function new(virtual cache_ro_int cache_ro_int_v);
    this.cache_data_v = new();
    this.cache_ro_int_v = cache_ro_int_v;
    this.cache_ro_int_v.cache_req = 1'b0;
    this.cache_ro_int_v.cache_addr = 'h0;
  endfunction : new


  task req_addr(integer addr);
    wait(!status_loaded);
    cache_data_v.cache_addr = addr;
    status_loaded = 1;
  endtask : req_addr


  task run();

    forever @(posedge cache_ro_int_v.ck) begin
      if(cache_drv_en && status_loaded) begin
        cache_ro_int_v.cache_addr = cache_data_v.cache_addr;
        cache_ro_int_v.cache_req = 1'b1;
        wait(cache_ro_int_v.cache_ack);
        @(posedge cache_ro_int_v.ck);
        cache_ro_int_v.cache_req = 1'b0;
        status_loaded = 0;
      end
    end

  endtask : run

endclass : cache_drv
