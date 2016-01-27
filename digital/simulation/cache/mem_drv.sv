
class mem_drv extends  transmittion #(.data_type(mem_data));
  integer mem_drv_en = 0;
  integer status_loaded = 0;

  mem_data mem_data_v;

  virtual cache_ro_int cache_ro_int_v;

  function new(virtual cache_ro_int cache_ro_int_v);
    this.mem_data_v = new();
    this.cache_ro_int_v = cache_ro_int_v;
    this.cache_ro_int_v.mem_ack = 1'b0;
  endfunction : new

  task ack_data(integer data);
    wait(!status_loaded);
    mem_data_v.mem_data = data;
    status_loaded = 1;
  endtask : ack_data

  task run();

    forever @(posedge cache_ro_int_v.ck) begin

      if(mem_drv_en && status_loaded) begin
        if(cache_ro_int_v.mem_req) begin
          cache_ro_int_v.mem_data = mem_data_v.mem_data;
          cache_ro_int_v.mem_ack = 1'b1;
          @(posedge cache_ro_int_v.ck)
          cache_ro_int_v.mem_ack = 1'b0;
          status_loaded = 0;
        end
      end
    end
  endtask : run

endclass : mem_drv
