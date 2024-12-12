// cache_tb.v
module cache_tb;
    // Test parameters
    localparam TRACE_LENGTH = 1500000;
    localparam CACHE_SIZE = 1024*8;    // 8KB cache
    localparam LINE_SIZE = 32;         // 32 bytes per line
    localparam ASSOCIATIVITY = 4;      // 4-way set associative
    localparam ADDR_WIDTH = 32;

    reg clk, rst, rd_en;
    reg [ADDR_WIDTH-1:0] addr;
    wire [31:0] misses, hits;
    wire hit_flag;
    
    real hit_ratio;
    integer trace_file, scan_file, done_reading;
    integer i;
    
    reg [31:0] trace_data [0:TRACE_LENGTH-1];
    reg [31:0] curr_addr;
    
    // DUT instantiation
    cache_controller #(
        .CACHE_SIZE(CACHE_SIZE),
        .LINE_SIZE(LINE_SIZE),
        .ASSOCIATIVITY(ASSOCIATIVITY),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) dut (
        .clk(clk),
        .rst(rst),
        .addr(addr),
        .rd_en(rd_en),
        .misses(misses),
        .hits(hits),
        .hit_flag(hit_flag)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Test stimulus
    initial begin
        // Initialize signals
        rst = 1;
        rd_en = 0;
        addr = 0;
        curr_addr = 0;
        
        // Read trace file
        trace_file = $fopen("addr_trace.txt", "r");
        if (trace_file == 0) begin
            $display("Error: Failed to open trace file");
            $finish;
        end

        // Read addresses from trace file
        done_reading = 0;
        for (i = 0; i < TRACE_LENGTH && !done_reading; i = i + 1) begin
            scan_file = $fscanf(trace_file, "%d\n", trace_data[i]);
            if (scan_file == -1) begin
                done_reading = 1;
            end
        end
        $fclose(trace_file);

        // Reset sequence
        #100;
        rst = 0;
        rd_en = 1;

        // Process trace
        for (i = 0; i < TRACE_LENGTH; i = i + 1) begin
            @(posedge clk);
            if (i == 0) begin
                curr_addr = trace_data[0];
            end
            else begin
                curr_addr = curr_addr + trace_data[i];
            end
            addr = curr_addr;
        end

        // Wait for final operations to complete
        repeat(10) @(posedge clk);
        rd_en = 0;

        // Calculate and display results
        hit_ratio = (hits * 100.0) / (hits + misses);
        
        $display("\n=== Cache Performance Statistics ===");
        $display("Configuration:");
        $display("  Cache Size: %0d bytes", CACHE_SIZE);
        $display("  Line Size: %0d bytes", LINE_SIZE);
        $display("  Associativity: %0d-way", ASSOCIATIVITY);
        $display("\nResults:");
        $display("  Total Hits: %0d", hits);
        $display("  Total Misses: %0d", misses);
        $display("  Total Accesses: %0d", hits + misses);
        $display("  Hit Ratio: %0.2f%%", hit_ratio);
        $display("===============================\n");
        
        $finish;
    end

    // Timeout protection
    initial begin
        #10000000 // 10ms timeout
        $display("Simulation timeout!");
        $finish;
    end

    // Waveform dumping
    initial begin
        $dumpfile("cache_sim.vcd");
        $dumpvars(0, cache_tb);
    end

endmodule
