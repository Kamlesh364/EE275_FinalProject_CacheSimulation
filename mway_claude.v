// cache_controller.v
module cache_controller #(
    parameter CACHE_SIZE = 1024*8,    // 8KB cache
    parameter LINE_SIZE = 32,         // 32 bytes per line
    parameter ASSOCIATIVITY = 4,      // 4-way set associative
    parameter ADDR_WIDTH = 32
)(
    input wire clk,
    input wire rst,
    input wire [ADDR_WIDTH-1:0] addr,
    input wire rd_en,
    output reg [31:0] misses,
    output reg [31:0] hits,
    output reg hit_flag
);

    // Calculate cache parameters
    localparam NUM_BLOCKS = CACHE_SIZE/LINE_SIZE;
    localparam NUM_SETS = (ASSOCIATIVITY == 0) ? 1 : (NUM_BLOCKS/ASSOCIATIVITY);
    localparam OFFSET_BITS = $clog2(LINE_SIZE);
    localparam INDEX_BITS = (ASSOCIATIVITY == 0) ? $clog2(CACHE_SIZE/LINE_SIZE) :
                                                  $clog2(CACHE_SIZE/(LINE_SIZE*ASSOCIATIVITY));
    localparam TAG_BITS = ADDR_WIDTH - (OFFSET_BITS + INDEX_BITS);

    // Cache storage
    reg [LINE_SIZE*8-1:0] cache_data [0:NUM_BLOCKS-1];
    reg [TAG_BITS-1:0] tag_array [0:NUM_BLOCKS-1];
    reg valid_array [0:NUM_BLOCKS-1];
    reg [ASSOCIATIVITY-1:0] lru_counter [0:NUM_SETS-1][0:ASSOCIATIVITY-1];

    // Address breakdown
    wire [TAG_BITS-1:0] tag;
    wire [INDEX_BITS-1:0] index;
    wire [OFFSET_BITS-1:0] offset;

    assign tag = addr[ADDR_WIDTH-1:OFFSET_BITS+INDEX_BITS];
    assign index = addr[OFFSET_BITS+INDEX_BITS-1:OFFSET_BITS];
    assign offset = addr[OFFSET_BITS-1:0];

    integer i, j;
    reg hit_found;
    reg done;
    reg [31:0] replace_way;
    reg [31:0] set_base;

    // LRU update task
    task update_lru;
        input [31:0] set_idx;
        input [31:0] way;
        integer k;
        begin
            for (k = 0; k < ASSOCIATIVITY; k = k + 1) begin
                if (lru_counter[set_idx][k] > lru_counter[set_idx][way]) begin
                    lru_counter[set_idx][k] = lru_counter[set_idx][k] - 1;
                end
            end
            lru_counter[set_idx][way] = ASSOCIATIVITY - 1;
        end
    endtask

    // Find LRU way function
    function [31:0] find_lru;
        input [31:0] set_idx;
        reg found;
        integer k;
        begin
            find_lru = 0;
            found = 0;
            for (k = 0; k < ASSOCIATIVITY && !found; k = k + 1) begin
                if (lru_counter[set_idx][k] == 0) begin
                    find_lru = k;
                    found = 1;
                end
            end
        end
    endfunction


    always @(posedge clk or posedge rst) begin
        if (rst) begin
            hits <= 0;
            misses <= 0;
            hit_flag <= 0;
            
            for (i = 0; i < NUM_SETS; i = i + 1) begin
                for (j = 0; j < ASSOCIATIVITY; j = j + 1) begin
                    valid_array[i*ASSOCIATIVITY + j] <= 0;
                    tag_array[i*ASSOCIATIVITY + j] <= 0;
                    lru_counter[i][j] <= j;
                end
            end
        end
        else if (rd_en) begin
            hit_found = 0;
            set_base = index * ASSOCIATIVITY;

            // Check for hit
            done = 0;
            for (i = 0; i < ASSOCIATIVITY && !done; i = i + 1) begin
                if (valid_array[set_base + i] && tag_array[set_base + i] == tag) begin
                    hit_found = 1;
                    replace_way = i;
                    done = 1;
                end
            end

            if (hit_found) begin
                hits <= hits + 1;
                hit_flag <= 1;
                update_lru(index, replace_way);
            end
            else begin
                misses <= misses + 1;
                hit_flag <= 0;
                replace_way = find_lru(index);
                tag_array[set_base + replace_way] <= tag;
                valid_array[set_base + replace_way] <= 1;
                update_lru(index, replace_way);
            end
        end
    end

endmodule
