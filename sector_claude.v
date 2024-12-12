// Cache parameters
`define WORD_SIZE 32
`define ADDR_WIDTH 32

module configurable_cache #(
    parameter CACHE_SIZE = 8192,     // Cache size in bytes
    parameter LINE_SIZE = 32,        // Cache line size in bytes
    parameter SECTOR_SIZE = 8,       // Sector size in bytes
    parameter ASSOCIATIVITY = 4,     // Set associativity
    // Derived parameters
    parameter SECTORS_PER_LINE = LINE_SIZE/SECTOR_SIZE,
    parameter NUM_LINES = CACHE_SIZE/LINE_SIZE,
    parameter NUM_SETS = NUM_LINES/ASSOCIATIVITY,
    parameter OFFSET_BITS = $clog2(SECTOR_SIZE),
    parameter SECTOR_INDEX_BITS = $clog2(SECTORS_PER_LINE),
    parameter SET_BITS = $clog2(NUM_SETS),
    parameter TAG_BITS = `ADDR_WIDTH - SET_BITS - SECTOR_INDEX_BITS - OFFSET_BITS
)(
    input wire clk,
    input wire rst,
    input wire [`ADDR_WIDTH-1:0] addr,
    output reg hit,
    output reg miss,
    output reg [31:0] total_hits,
    output reg [31:0] total_misses,
    output wire [31:0] sectors_per_line,
    output wire [31:0] num_sets,
    output wire [31:0] tag_bits
);

    // Cache storage structures
    reg [TAG_BITS-1:0] tag_array [0:NUM_LINES-1];
    reg valid_array [0:NUM_LINES-1];
    reg [SECTORS_PER_LINE-1:0] valid_sectors [0:NUM_LINES-1]; // Valid bits per sector
    reg [$clog2(ASSOCIATIVITY)-1:0] lru_counter [0:NUM_LINES-1];

    // Address breakdown
    wire [TAG_BITS-1:0] addr_tag;
    wire [SET_BITS-1:0] set_index;
    wire [SECTOR_INDEX_BITS-1:0] sector_index;
    wire [OFFSET_BITS-1:0] offset;

    // Output configuration parameters for monitoring
    assign sectors_per_line = SECTORS_PER_LINE;
    assign num_sets = NUM_SETS;
    assign tag_bits = TAG_BITS;

    // Address parsing
    assign addr_tag = addr[`ADDR_WIDTH-1:`ADDR_WIDTH-TAG_BITS];
    assign set_index = addr[`ADDR_WIDTH-TAG_BITS-1:`ADDR_WIDTH-TAG_BITS-SET_BITS];
    assign sector_index = addr[SECTOR_INDEX_BITS+OFFSET_BITS-1:OFFSET_BITS];
    assign offset = addr[OFFSET_BITS-1:0];

    // Internal signals
    reg [31:0] current_set_base;
    reg found_hit;
    reg [31:0] hit_way;
    reg [31:0] lru_way;
    reg [$clog2(ASSOCIATIVITY)-1:0] min_counter;

    // Performance counters
    reg [31:0] sector_misses;
    reg [31:0] line_misses;

    // Initialize cache
    integer i, j;
    initial begin
        for (i = 0; i < NUM_LINES; i = i + 1) begin
            valid_array[i] = 0;
            tag_array[i] = 0;
            lru_counter[i] = i % ASSOCIATIVITY;
            for (j = 0; j < SECTORS_PER_LINE; j = j + 1) begin
                valid_sectors[i][j] = 0;
            end
        end
        total_hits = 0;
        total_misses = 0;
        sector_misses = 0;
        line_misses = 0;
    end

    // Main cache logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Reset logic
            for (i = 0; i < NUM_LINES; i = i + 1) begin
                valid_array[i] <= 0;
                tag_array[i] <= 0;
                lru_counter[i] <= i % ASSOCIATIVITY;
                for (j = 0; j < SECTORS_PER_LINE; j = j + 1) begin
                    valid_sectors[i][j] <= 0;
                end
            end
            total_hits <= 0;
            total_misses <= 0;
            sector_misses <= 0;
            line_misses <= 0;
            hit <= 0;
            miss <= 0;
        end
        else begin
            // Calculate set base address
            current_set_base = set_index * ASSOCIATIVITY;
            found_hit = 0;
            hit <= 0;
            miss <= 0;

            // Check for hit in the set
            for (i = 0; i < ASSOCIATIVITY; i = i + 1) begin
                if (valid_array[current_set_base + i] && 
                    tag_array[current_set_base + i] == addr_tag) begin
                    // Check if the specific sector is valid
                    if (valid_sectors[current_set_base + i][sector_index]) begin
                        found_hit = 1;
                        hit_way = i;
                    end
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
            end
            else begin
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
                if (!valid_array[current_set_base + lru_way]) begin
                    line_misses <= line_misses + 1;
                end
                valid_array[current_set_base + lru_way] <= 1;
                tag_array[current_set_base + lru_way] <= addr_tag;
                valid_sectors[current_set_base + lru_way][sector_index] <= 1;

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

// // Testbench
// module cache_tb;
//     parameter CACHE_SIZE = 8192;
//     parameter LINE_SIZE = 32;
//     parameter SECTOR_SIZE = 8;
//     parameter ASSOCIATIVITY = 4;

//     reg clk;
//     reg rst;
//     reg [31:0] addr;
//     wire hit;
//     wire miss;
//     wire [31:0] total_hits;
//     wire [31:0] total_misses;
//     wire [31:0] sectors_per_line;
//     wire [31:0] num_sets;
//     wire [31:0] tag_bits;

//     // Instantiate cache
//     configurable_cache #(
//         .CACHE_SIZE(CACHE_SIZE),
//         .LINE_SIZE(LINE_SIZE),
//         .SECTOR_SIZE(SECTOR_SIZE),
//         .ASSOCIATIVITY(ASSOCIATIVITY)
//     ) cache_inst (
//         .clk(clk),
//         .rst(rst),
//         .addr(addr),
//         .hit(hit),
//         .miss(miss),
//         .total_hits(total_hits),
//         .total_misses(total_misses),
//         .sectors_per_line(sectors_per_line),
//         .num_sets(num_sets),
//         .tag_bits(tag_bits)
//     );

//     // Test sequence
//     initial begin
//         // Initialize inputs
//         clk = 0;
//         rst = 1;
//         addr = 0;

//         // Release reset
//         #20 rst = 0;

//         // Display configuration
//         $display("Cache Configuration:");
//         $display("Cache Size: %0d bytes", CACHE_SIZE);
//         $display("Line Size: %0d bytes", LINE_SIZE);
//         $display("Sector Size: %0d bytes", SECTOR_SIZE);
//         $display("Associativity: %0d-way", ASSOCIATIVITY);
//         $display("Sectors per line: %0d", sectors_per_line);
//         $display("Number of sets: %0d", num_sets);
//         $display("Tag bits: %0d", tag_bits);

//         // Test different access patterns
//         test_sequential_access();
//         test_random_access();
//         test_sector_reuse();

//         // Display results
//         #100;
//         $display("\nTest Results:");
//         $display("Total Hits: %0d", total_hits);
//         $display("Total Misses: %0d", total_misses);
//         $display("Hit Rate: %0.2f%%", 
//             (total_hits * 100.0) / (total_hits + total_misses));
        
//         $finish;
//     end

//     // Clock generation
//     always #5 clk = ~clk;

//     // Test tasks
//     task test_sequential_access;
//         integer i;
//         begin
//             $display("\nTesting Sequential Access Pattern");
//             for (i = 0; i < 1000; i = i + SECTOR_SIZE) begin
//                 @(posedge clk);
//                 addr = i;
//                 #1;
//             end
//         end
//     endtask

//     task test_random_access;
//         integer i;
//         begin
//             $display("\nTesting Random Access Pattern");
//             for (i = 0; i < 1000; i = i + 1) begin
//                 @(posedge clk);
//                 addr = $random % (1024 * 64); // Random address in 64KB range
//                 #1;
//             end
//         end
//     endtask

//     task test_sector_reuse;
//         integer i, base_addr;
//         begin
//             $display("\nTesting Sector Reuse Pattern");
//             base_addr = 0;
//             for (i = 0; i < 1000; i = i + 1) begin
//                 @(posedge clk);
//                 // Access different sectors within the same line
//                 addr = base_addr + ((i % SECTORS_PER_LINE) * SECTOR_SIZE);
//                 #1;
//                 if (i % 100 == 99) base_addr = base_addr + LINE_SIZE;
//             end
//         end
//     endtask

// endmodule