module tb();
    // Cache configuration parameters
    parameter CACHE_SIZE = (1024*64);     // in KB 
    parameter LINE_SIZE = 32;            // in B per line
    parameter ASSOCIATIVITY = 4;        // m-way set associative
    
    // Test parameters
    `define LENGTH 1500000
    
    // Testbench signals
    reg clk, rst;
    reg [31:0] addr;
    wire hit, miss;
    wire [31:0] total_hits, total_misses;
    wire [31:0] num_sets, tag_bits;
    
    // Performance metrics
    real hit_ratio, percentage;
    real miss_count, hit_count;
    
    // Trace file handling
    integer file, stat, i, j;
    reg signed [31:0] trace_delta[0:`LENGTH-1];
    reg [31:0] trace_addr[0:`LENGTH-1];
    
    // Performance statistics
    reg [31:0] accesses_per_set[0:(CACHE_SIZE/(LINE_SIZE*ASSOCIATIVITY))-1];
    
    // Instantiate cache
    configurable_cache #(
        .CACHE_SIZE(CACHE_SIZE),
        .LINE_SIZE(LINE_SIZE),
        .ASSOCIATIVITY(ASSOCIATIVITY)
    ) cache_inst (
        .clk(clk),
        .rst(rst),
        .addr(addr),
        .hit(hit),
        .miss(miss),
        .total_hits(total_hits),
        .total_misses(total_misses),
        .num_sets(num_sets),
        .tag_bits(tag_bits)
    );

    // Initialize performance counters
    initial begin
        percentage = 100.00;
        for (i = 0; i < CACHE_SIZE/(LINE_SIZE*ASSOCIATIVITY); i = i + 1)
            accesses_per_set[i] = 0;
    end

    // Read trace file
    initial begin
        file = $fopen("addr_trace.txt", "r");
        if (file == 0) begin
            $display("Error: Could not open trace file");
            $finish;
        end
        
        i = 0;
        while (!$feof(file) && i < `LENGTH) begin
            stat = $fscanf(file, "%d\n", trace_delta[i]);
            if (stat == 1) i = i + 1;
        end
        $fclose(file);
        
        // Convert deltas to absolute addresses
        trace_addr[0] = trace_delta[0];
        for (i = 1; i < `LENGTH; i = i + 1) begin
            trace_addr[i] = trace_addr[i-1] + trace_delta[i];
        end
    end

    // Clock generation
    always #5 clk = ~clk;

    // Main test sequence
    initial begin
        // Initialize
        clk = 0;
        rst = 1;
        addr = 0;
        
        // Print configuration
        $display("\nCache Configuration:");
        $display("Cache Size: %0d bytes", CACHE_SIZE);
        $display("Line Size: %0d bytes", LINE_SIZE);
        $display("Associativity: %0d-way", ASSOCIATIVITY);
        
        // Reset sequence
        @(posedge clk);
        rst = 0;
        
        // Process trace
        for (j = 0; j < `LENGTH; j = j + 1) begin
            @(posedge clk);
            addr = trace_addr[j];
            
            // Collect per-set statistics
            if (hit) begin
                accesses_per_set[addr[($clog2(CACHE_SIZE/(LINE_SIZE*ASSOCIATIVITY))+$clog2(LINE_SIZE)-1):$clog2(LINE_SIZE)]] = 
                    accesses_per_set[addr[($clog2(CACHE_SIZE/(LINE_SIZE*ASSOCIATIVITY))+$clog2(LINE_SIZE)-1):$clog2(LINE_SIZE)]] + 1;
            end
        end
        
        // Calculate final statistics
        @(posedge clk);
        miss_count = total_misses;
        hit_count = total_hits;
        hit_ratio = (hit_count/(miss_count + hit_count)) * percentage;
        
        // Print results
        $display("\nPerformance Results:");
        $display("Hit Ratio: %7.2f%%", hit_ratio);
        $display("Cache Hits: %0d", total_hits);
        $display("Cache Misses: %0d", total_misses);
        $display("Total Accesses: %0d", total_hits + total_misses);
        
        // // Print set utilization
        // $display("\nSet Utilization:");
        // for (i = 0; i < CACHE_SIZE/(LINE_SIZE*ASSOCIATIVITY); i = i + 1) begin
        //     if (accesses_per_set[i] > 0)
        //         $display("Set %0d: %0d accesses", i, accesses_per_set[i]);
        // end
        
        $finish;
    end
    
    // Temporal locality tracking
    integer current_index;
    reg [31:0] reuse_distance[0:1023];
    reg [31:0] reuse_count;
    
    always @(posedge clk) begin
        if (!rst && (hit || miss)) begin
            // Update reuse distance tracking
            current_index = -1;
            for (i = 0; i < 1024; i = i + 1) begin
                if (reuse_distance[i] == addr) begin
                    current_index = i;
                    i = 1024; // Exit loop
                end
            end
            
            if (current_index >= 0) begin
                reuse_count = reuse_count + 1;
            end
            
            // Shift in new address
            for (i = 1023; i > 0; i = i - 1) begin
                reuse_distance[i] = reuse_distance[i-1];
            end
            reuse_distance[0] = addr;
        end
    end

endmodule
