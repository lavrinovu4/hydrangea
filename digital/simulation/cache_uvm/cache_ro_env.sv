class cache_ro_env extends uvm_env;

  `uvm_component_utils(cache_ro_env)

  cache_ro_drv cache_ro_drv_v;
  mem_drv mem_drv_v;

  cache_ro_mon cache_ro_mon_v;
  mem_mon mem_mon_v;
  global_scoreboard global_scoreboard_v;

  typedef uvm_sequencer #(cache_ro_transaction) cache_ro_sqr;
  cache_ro_sqr cache_ro_sqr_v;


  function new(string name, uvm_component parent);
    super.new(name, parent);

    cache_ro_drv_v      = cache_ro_drv     ::type_id::create("cache_ro_drv_v", this);
    mem_drv_v           = mem_drv          ::type_id::create("mem_drv_v", this);

    cache_ro_mon_v      = cache_ro_mon     ::type_id::create("cache_ro_mon_v", this);
    mem_mon_v           = mem_mon          ::type_id::create("mem_mon_v", this);

    global_scoreboard_v = global_scoreboard::type_id::create("global_scoreboard_v", this);

    cache_ro_sqr_v      = cache_ro_sqr     ::type_id::create("cache_ro_sqr_v", this);

  endfunction: new

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
  endfunction: build_phase

  function void connect_phase(uvm_phase phase);
    cache_ro_mon_v.item_collected_port.connect(global_scoreboard_v.cache_ro_mon_port);
    cache_ro_drv_v.item_collected_port.connect(global_scoreboard_v.cache_ro_drv_port);
    mem_mon_v.item_collected_port.connect(global_scoreboard_v.mem_mon_port);
    mem_drv_v.item_collected_port.connect(global_scoreboard_v.mem_drv_port);

    cache_ro_drv_v.seq_item_port.connect(cache_ro_sqr_v.seq_item_export);
  endfunction : connect_phase

endclass: cache_ro_env
