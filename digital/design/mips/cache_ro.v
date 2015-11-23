module cache_ro (
  i_ck,
  i_rb,

  i_cache_addr,
  i_cache_req,

  o_cache_data,
  o_cache_ack,

  i_mem_ack,
  i_mem_data,
  o_mem_req,
  o_mem_addr
);


  input         i_ck          ;
  input         i_rb          ;

  input  [29:0] i_cache_addr  ;
  input         i_cache_req   ;
  output [31:0] o_cache_data  ;
  output        o_cache_ack   ;

  input         i_mem_ack     ;
  input  [31:0] i_mem_data    ;
  output        o_mem_req     ;
  output [29:0] o_mem_addr    ;

  parameter BLOCK_WIDTH = 3;
  parameter INDEX_WIDTH = 5;
  parameter WAYS_SIZE = 8;
  localparam TAG_WIDTH = 30 - BLOCK_WIDTH - INDEX_WIDTH;

  localparam BLOCK_BIT_WIDTH = (2**BLOCK_WIDTH) * 32;

  wire [TAG_WIDTH - 1:0]    tag_addr;
  wire [INDEX_WIDTH - 1:0]  ind_addr;
  wire [BLOCK_WIDTH - 1:0]  bl_addr ;

  wire [WAYS_SIZE - 1:0]     cache_way_we;
  wire [WAYS_SIZE - 1:0]     valid_way;
  wire [WAYS_SIZE - 1:0]     hit_way;

  reg [BLOCK_BIT_WIDTH - 1:0]  block_data_w;

  wire hit;
  wire miss;
  reg [INDEX_WIDTH - 1:0] ind_addr_rg;
  wire all_valid;
  reg [WAYS_SIZE - 1:0] counter_rand;
  reg [WAYS_SIZE - 1:0] cache_way_sel;

  wire cache_we;

  reg [BLOCK_WIDTH - 1:0] counter_adr_gen;
  reg [31:0] buf_mem [2**BLOCK_WIDTH - 1:0];

  genvar i;
  genvar k;

  reg [1:0] state;

  parameter IDLE           = 0,
            COUNT          = 1,
            CACHE_SAFE     = 2,
            WAIT_DATA_WRITE_CACHE = 3;

  assign {tag_addr, ind_addr, bl_addr} = i_cache_addr;

  generate
    if(WAYS_SIZE == 8) begin
      
      always @(posedge i_ck, negedge i_rb) begin
        if(~i_rb)
          counter_rand <= 3'h0;
        else if(i_cache_req)
          counter_rand <= counter_rand + 3'h1;
      end
    
      always @* begin
        cache_way_sel = 0;
    
        if(all_valid)
          cache_way_sel[counter_rand] = 1'b1;
        else begin
          case(1'b0)
            valid_way[0]: cache_way_sel = 8'b0000_0001;
            valid_way[1]: cache_way_sel = 8'b0000_0010;
            valid_way[2]: cache_way_sel = 8'b0000_0100;
            valid_way[3]: cache_way_sel = 8'b0000_1000;
            valid_way[4]: cache_way_sel = 8'b0001_0000;
            valid_way[5]: cache_way_sel = 8'b0010_0000;
            valid_way[6]: cache_way_sel = 8'b0100_0000;
            valid_way[7]: cache_way_sel = 8'b1000_0000;
            default:      cache_way_sel = 8'b0000_0000;
          endcase
        end
      end

    end
  endgenerate

  assign cache_way_we = cache_way_sel & {WAYS_SIZE{cache_we}};

  generate 

    for(i = 0; i < WAYS_SIZE; i = i + 1) begin: ways

      wire [BLOCK_BIT_WIDTH - 1:0]   block_data_cached;
      wire [31:0]   data_cached_and_valid_way;
      reg [31:0]    data_cached;
      wire [TAG_WIDTH-1:0] tag_cached_way;

      sram_cache #(
        .ADDR_WIDTH(INDEX_WIDTH   ),
        .DATA_WIDTH(TAG_WIDTH + 1 )
      )
      u_tag_mem(
        .i_ck     ( i_ck     ),              
        .i_addr   ( ind_addr ),                
        .i_we     ( cache_way_we[i] ),              
        .i_data_w ( {1'b1, tag_addr} ),
      
        .o_data_r ( {valid_way[i], tag_cached_way} )
      );
    
      assign hit_way[i] = ( tag_addr == tag_cached_way ) & valid_way[i];
    
    
      sram_cache #(
        .ADDR_WIDTH(INDEX_WIDTH      ),
        .DATA_WIDTH(BLOCK_BIT_WIDTH  )
      )
      u_block_mem(
        .i_ck     ( i_ck               ),              
        .i_addr   ( ind_addr           ),                
        .i_we     ( cache_way_we[i]    ),              
        .i_data_w ( block_data_w       ),                  
      
        .o_data_r ( block_data_cached  )
      );
    
      //TODO: only for BLOCK_WIDTH = 3(2^3 = 8)
      if(BLOCK_WIDTH == 3) begin
        always @* begin
          data_cached = block_data_cached[31:0];
      
          case(bl_addr)
            1: data_cached = block_data_cached[63:32];
            2: data_cached = block_data_cached[95:64];
            3: data_cached = block_data_cached[127:96];
            4: data_cached = block_data_cached[159:128];
            5: data_cached = block_data_cached[191:160];
            6: data_cached = block_data_cached[223:192];
            7: data_cached = block_data_cached[255:224];
          endcase
        end
      end
    
      //TODO: trouble data_cached_and_valid_way became a multi dim array
      if(i == 0)
        assign data_cached_and_valid_way = data_cached & {32{hit_way[i]}};
      else
        assign data_cached_and_valid_way = data_cached & {32{hit_way[i]}} | ways[i - 1].data_cached_and_valid_way;

    end //for 

  endgenerate

  assign hit = |hit_way;

  always @(posedge i_ck, negedge i_rb) begin
    if(~i_rb)
      ind_addr_rg <= 0;
    else
      ind_addr_rg <= ind_addr;
  end

  assign o_cache_ack = (ind_addr == ind_addr_rg) & i_cache_req & hit; //TODO:check it correct handled
  assign o_cache_data = ways[WAYS_SIZE - 1].data_cached_and_valid_way;

  assign miss = (ind_addr == ind_addr_rg) & i_cache_req & ~hit;

  assign all_valid = &valid_way;


  always @(posedge i_ck, negedge i_rb) begin
    if(~i_rb)
      counter_adr_gen <= 0;
    else if(miss & i_mem_ack)
      counter_adr_gen <= counter_adr_gen + 1;
  end

  assign o_mem_addr = {i_cache_addr[29:BLOCK_WIDTH], counter_adr_gen };

  always @(posedge i_ck) begin
    if(i_mem_ack)
      buf_mem[counter_adr_gen]<= i_mem_data;
  end

  generate
    
    for(k = 0; k < 2**BLOCK_WIDTH; k = k + 1) begin

    always @* 
      block_data_w[32*(k+1)-1 : 32*k] = buf_mem[k];

    end

  endgenerate

  always @(posedge i_ck, negedge i_rb) begin
    if(~i_rb)
      state <= IDLE;
    else begin

      case(state)
        IDLE:
              if(miss)
                state <= COUNT;

        COUNT:
              if((counter_adr_gen == {BLOCK_WIDTH{1'b1}}) & i_mem_ack)
                state <= CACHE_SAFE;

        CACHE_SAFE:
              state <= WAIT_DATA_WRITE_CACHE;

        WAIT_DATA_WRITE_CACHE:
              state <= IDLE;

      endcase

    end
  end

  assign cache_we = state == CACHE_SAFE;
  assign o_mem_req = state == COUNT;

endmodule