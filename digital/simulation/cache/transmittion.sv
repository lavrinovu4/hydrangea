
class transmittion #(type data_type = integer);
  data_type data;
  bit status_send = 1'b0;

  function void send(data_type data);
    if (~status_send) begin
      status_send = 1'b1;
      this.data = data;
    end
  endfunction : send

  task get(output data_type get_data);
    wait(status_send);
    get_data = this.data;
    status_send = 1'b0;
  endtask : get

endclass : transmittion
