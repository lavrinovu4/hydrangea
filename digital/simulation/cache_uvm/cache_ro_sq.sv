class cache_ro_sq extends uvm_sequence #(cache_ro_transaction);
  `uvm_object_utils(cache_ro_sq)

  cache_ro_transaction cache_ro_trans;

  int count = 1;
  string acase = "SQ_INC";

  function new(string name = "");
    super.new(name);
    cache_ro_trans = new();
  endfunction : new

  task body();

    case(acase)
      "SQ_INC":  case_inc(count);
      "SQ_JMP":  case_jmp(count);
      "SQ_LOOP": case_loop(count, count);
    endcase

  endtask : body


  task case_inc(int count);

    for (int i = 0; i < count; i++) begin
      cache_ro_trans.cache_addr++;

      start_item(cache_ro_trans);
      finish_item(cache_ro_trans);
    end
  endtask

  task case_jmp(int count);

    for (int i = 0; i < count; i++) begin
      void'(cache_ro_trans.randomize());

      start_item(cache_ro_trans);
      finish_item(cache_ro_trans);
    end
  endtask

  task case_loop(int count_loop, int count_len);

    int first_addr;

    case_jmp(1);
    first_addr = cache_ro_trans.cache_addr;

    for (int i = 0; i < count_loop; i++) begin

      case_inc(count_len);
      cache_ro_trans.cache_addr = first_addr;
    end
  endtask

endclass : cache_ro_sq
