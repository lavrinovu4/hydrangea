
class global_scoreboard extends  uvm_scoreboard;
  `uvm_component_utils(global_scoreboard)

  `uvm_analysis_imp_decl(_cache_ro_mon)
  `uvm_analysis_imp_decl(_mem_mon)

  `uvm_analysis_imp_decl(_cache_ro_drv)
  `uvm_analysis_imp_decl(_mem_drv)

  uvm_analysis_imp_cache_ro_mon #(cache_ro_transaction, global_scoreboard) cache_ro_mon_port;
  uvm_analysis_imp_mem_mon #(mem_transaction, global_scoreboard) mem_mon_port;

  uvm_analysis_imp_cache_ro_drv #(cache_ro_transaction, global_scoreboard) cache_ro_drv_port;
  uvm_analysis_imp_mem_drv #(mem_transaction, global_scoreboard) mem_drv_port;

  // int memory [2**9 -1:0];
  int memory [];
  // int mem_load;

  int mem_mon_count = 0;
  int mem_drv_count = 0;

  int cache_ro_mon_count = 0;
  int cache_ro_drv_count = 0;

  int num_trans = 0;
  int num_checks = 0;
  int num_error = 0;

  mem_transaction mem_trans;
  cache_ro_transaction cache_ro_trans;

  // Constructor
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction : new

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    cache_ro_mon_port = new("cache_ro_mon_port", this);
    cache_ro_drv_port = new("cache_ro_drv_port", this);

    mem_mon_port = new("mem_mon_port", this);
    mem_drv_port = new("mem_drv_port", this);

    mem_trans = new();
    cache_ro_trans = new();

  endfunction : build_phase

  function void write_cache_ro_mon(cache_ro_transaction cache_ro_trans);
    `uvm_info("cache_ro_mon", $sformatf("receiving \naddr: %h, data: %h", cache_ro_trans.cache_addr, cache_ro_trans.cache_data), UVM_LOW);
    cache_ro_mon_count++;

    if((cache_ro_mon_count -  cache_ro_drv_count) == 0) begin

      if(memory[this.cache_ro_trans.cache_addr] != cache_ro_trans.cache_data) begin
        `uvm_error("cache_ro_mon", $sformatf("Wrong data received \ncache_ro_data: %h, mem_data: %h", cache_ro_trans.cache_data, memory[this.cache_ro_trans.cache_addr]));
        num_error++;
      end

      num_checks++;
    end else
      `uvm_error("cache_ro_mon", $sformatf("Resync \ncache_mon_count: %h, cache_drv_count: %h", cache_ro_mon_count, cache_ro_drv_count));

    num_trans++;
  endfunction : write_cache_ro_mon

  function void write_mem_mon(mem_transaction mem_trans);
    `uvm_info("mem_mon", $sformatf("receiving \naddr: %h, data: %h", mem_trans.mem_addr, mem_trans.mem_data), UVM_LOW);

    this.mem_trans = mem_trans;
    mem_mon_count++;

    if((mem_mon_count -  mem_drv_count) != 1)
      `uvm_error("mem_drv", $sformatf("Resync \nmem_mon_count: %h, mem_drv_count: %h", mem_mon_count, mem_drv_count));

    num_trans++;
  endfunction : write_mem_mon

  function void write_cache_ro_drv(cache_ro_transaction cache_ro_trans);
    `uvm_info("cache_ro_drv", $sformatf("receiving \naddr: %h, data: %h", cache_ro_trans.cache_addr, cache_ro_trans.cache_data), UVM_LOW);
    cache_ro_drv_count++;
    this.cache_ro_trans = cache_ro_trans;
    num_trans++;
  endfunction : write_cache_ro_drv

  function void write_mem_drv(mem_transaction mem_trans);
    `uvm_info("mem_drv", $sformatf("receiving \naddr: %h, data: %h", mem_trans.mem_addr, mem_trans.mem_data), UVM_LOW);

    // if(!mem_load) begin
      memory = mem_trans.memory;
    //   mem_load = 1;
    // end
    // memory[this.mem_trans.mem_addr] = mem_trans.mem_data;

    mem_drv_count++;

    num_trans++;
  endfunction : write_mem_drv

  function void extract_phase(uvm_phase phase);
    `uvm_info("scoreboard", $sformatf("Scoreboard reposrts:"), UVM_LOW);
    `uvm_info("scoreboard", $sformatf("num_trans:  %d", num_trans), UVM_LOW);
    `uvm_info("scoreboard", $sformatf("num_checks: %d", num_checks), UVM_LOW);
    `uvm_info("scoreboard", $sformatf("num_error:  %d", num_error), UVM_LOW);

    if(num_error == 0) begin
      `uvm_info("scoreboard", {"Test: OK!"}, UVM_LOW);
    end else
      `uvm_info("scoreboard", {"Test: FAILED!"}, UVM_LOW);

  endfunction : extract_phase

endclass : global_scoreboard
