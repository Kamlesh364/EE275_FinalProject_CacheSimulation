// Cache parameters
`define WORD_SIZE 32
`define ADDR_WIDTH 32

module configurable_cache #(
    parameter CACHE_SIZE = 8192,    // Cache size in bytes
    parameter LINE_SIZE = 32,       // Cache line size in bytes
    parameter ASSOCIATIVITY = 4,    // Set associativity
    
    // Derived parameters
    parameter NUM_LINES = CACHE_SIZE/LINE_SIZE,
    parameter NUM_SETS = NUM_LINES/ASSOCIATIVITY,
    parameter OFFSET_BITS = $clog2(LINE_SIZE),
    parameter SET_BITS = $clog2(NUM_SETS),
    parameter TAG_BITS = `ADDR_WIDTH - SET_BITS - OFFSET_BITS
)(
    input wire clk,
    input wire rst,
    input wire [`ADDR_WIDTH-1:0] addr,
    output reg hit,
    output reg miss,
    output reg [31:0] total_hits,
    output reg [31:0] total_misses,
    output wire [31:0] num_sets,
    output wire [31:0] tag_bits
);

    // Cache storage structures
    reg [TAG_BITS-1:0] tag_array [0:NUM_LINES-1];
    reg valid_array [0:NUM_LINES-1];
    reg [$clog2(ASSOCIATIVITY)-1:0] lru_counter [0:NUM_LINES-1];

    // Address breakdown
    wire [TAG_BITS-1:0] addr_tag;
    wire [SET_BITS-1:0] set_index;
    wire [OFFSET_BITS-1:0] offset;

    // Output configuration parameters
    assign num_sets = NUM_SETS;
    assign tag_bits = TAG_BITS;

    // Address parsing
    assign addr_tag = addr[`ADDR_WIDTH-1:`ADDR_WIDTH-TAG_BITS];
    assign set_index = addr[`ADDR_WIDTH-TAG_BITS-1:`ADDR_WIDTH-TAG_BITS-SET_BITS];
    assign offset = addr[OFFSET_BITS-1:0];

    // Internal signals
    reg [31:0] current_set_base;
    reg found_hit;
    reg [31:0] hit_way;
    reg [31:0] lru_way;
    reg [$clog2(ASSOCIATIVITY)-1:0] min_counter;

    // Initialize cache
    integer i;
    initial begin
        for (i = 0; i < NUM_LINES; i = i + 1) begin
            valid_array[i] = 0;
            tag_array[i] = 0;
            lru_counter[i] = i % ASSOCIATIVITY;
        end
        total_hits = 0;
        total_misses = 0;
    end

    // Main cache logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Reset logic
            for (i = 0; i < NUM_LINES; i = i + 1) begin
                valid_array[i] <= 0;
                tag_array[i] <= 0;
                lru_counter[i] <= i % ASSOCIATIVITY;
            end
            total_hits <= 0;
            total_misses <= 0;
            hit <= 0;
            miss <= 0;
        end else begin
            // Calculate set base address
            current_set_base = set_index * ASSOCIATIVITY;
            found_hit = 0;
            hit <= 0;
            miss <= 0;

            // Check for hit in the set
            for (i = 0; i < ASSOCIATIVITY; i = i + 1) begin
                if (valid_array[current_set_base + i] && 
                    tag_array[current_set_base + i] == addr_tag) begin
                    found_hit = 1;
                    hit_way = i;
                end
            end

            if (found_hit) begin
                // Cache hit
                hit <= 1;
                total_hits <= total_hits + 1;
                
                // Update LRU counters
                for (i = 0; i < ASSOCIATIVITY; i = i + 1) begin
                    if (lru_counter[current_set_base + i] > 
                        lru_counter[current_set_base + hit_way]) begin
                        lru_counter[current_set_base + i] <= 
                            lru_counter[current_set_base + i] - 1;
                    end
                end
                lru_counter[current_set_base + hit_way] <= ASSOCIATIVITY - 1;
            end else begin
                // Cache miss
                miss <= 1;
                total_misses <= total_misses + 1;

                // Find LRU way
                min_counter = ASSOCIATIVITY - 1;
                lru_way = 0;
                for (i = 0; i < ASSOCIATIVITY; i = i + 1) begin
                    if (lru_counter[current_set_base + i] < min_counter) begin
                        min_counter = lru_counter[current_set_base + i];
                        lru_way = i;
                    end
                end

                // Update cache line
                valid_array[current_set_base + lru_way] <= 1;
                tag_array[current_set_base + lru_way] <= addr_tag;

                // Update LRU counters
                for (i = 0; i < ASSOCIATIVITY; i = i + 1) begin
                    if (lru_counter[current_set_base + i] > 
                        lru_counter[current_set_base + lru_way]) begin
                        lru_counter[current_set_base + i] <= 
                            lru_counter[current_set_base + i] - 1;
                    end
                end
                lru_counter[current_set_base + lru_way] <= ASSOCIATIVITY - 1;
            end
        end
    end
endmodule
