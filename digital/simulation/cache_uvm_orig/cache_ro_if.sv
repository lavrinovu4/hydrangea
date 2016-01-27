interface cache_ro_if();

  logic              ck;

  logic  [29:0]      cache_addr;
  logic              cache_req = 1'b0;
  logic [31:0]       cache_data;
  logic              cache_ack;

  logic              mem_ack = 1'b0;
  logic [31:0]       mem_data;
  logic              mem_req;
  logic  [29:0]      mem_addr;

  int memory [2**9 - 1:0];

  sequence first_access(logic req, logic [29:0] addr);
    req && !memory[addr];
  endsequence

  sequence block_load_to_cache;
    ((cache_req & ~cache_ack) throughout (##[1:2] (first_access(mem_req, mem_addr) ##[1:9] mem_ack) [*8])) ##2 cache_ack;
  endsequence

  property miss_behav;
    @(posedge ck)
    $rose(cache_req) ##0 first_access(cache_req, cache_addr) |-> block_load_to_cache;
  endproperty

  MISS_BEHAV: assert property(miss_behav);



  sequence next_access(logic req, logic [29:0] addr);
    req && memory[addr];
  endsequence

  sequence hit_behav_s;
    (~mem_req & ~mem_ack) throughout ((cache_req & ~cache_ack) [*0:1] ##1 cache_ack);
  endsequence

  property hit_behav_p;
    @(posedge ck)
    $rose(cache_req) ##0 next_access(cache_req, cache_addr) |-> hit_behav_s;
  endproperty

  HIT_BEHAV: assert property(hit_behav_p);


  covergroup cache_bus_cover @(posedge cache_req);

     option.per_instance = 1;

     address : coverpoint cache_addr {
       bins low    = {[0:255]};
       bins med    = {[256:511]};
     }
  endgroup

  cache_bus_cover cache_cov = new();

endinterface
