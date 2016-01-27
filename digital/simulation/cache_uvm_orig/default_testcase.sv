class default_testcase extends uvm_test;

  `uvm_component_utils(default_testcase)

  cache_ro_env cr_env;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction: new

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    cr_env = cache_ro_env::type_id::create(.name("cr_env"), .parent(this));

  endfunction: build_phase

  task run_phase(uvm_phase phase);
    cache_ro_sq cr_seq;

    phase.raise_objection(.obj(this));
    cr_seq = cache_ro_sq::type_id::create("cache_ro_sq", this);

    cr_seq.count = 20;
    cr_seq.acase = "SQ_INC";
    cr_seq.start(cr_env.cache_ro_sqr_v);

    cr_seq.count = 5;
    cr_seq.acase = "SQ_JMP";
    cr_seq.start(cr_env.cache_ro_sqr_v);

    cr_seq.count = 10;
    cr_seq.acase = "SQ_LOOP";
    cr_seq.start(cr_env.cache_ro_sqr_v);

    cr_seq.cache_ro_trans.cache_addr = 0;
    cr_seq.count = 5;
    cr_seq.acase = "SQ_LOOP";
    cr_seq.start(cr_env.cache_ro_sqr_v);

    for (int i = 0; i < 8; i++) begin
      /* code */
      cr_seq.cache_ro_trans.cache_addr = i << 6;
      cr_seq.count = 8;
      cr_seq.acase = "SQ_INC";
      cr_seq.start(cr_env.cache_ro_sqr_v);
    end

    phase.drop_objection(.obj(this));

  endtask: run_phase

endclass: default_testcase
