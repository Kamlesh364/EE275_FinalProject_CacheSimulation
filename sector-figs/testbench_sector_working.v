module tb();
  reg clk_41, rst_41;
  reg [30:0] adder_41;
  
  wire [30:0] misses_41, hits_41;
  real hit_ratio_41, per = 100.00;
  real m, h;

  `define Length 1500000
  integer p, r, c;
  integer file, stat, out, i, j;
  reg signed [30:0] face[0:`Length-1];
  reg [30:0] actual[0:`Length-1];
  
  // Instantiate the sector-mapped cache
  test t1(
    .adder_41(adder_41),
    .clk_41(clk_41),
    .rst_41(rst_41),
    .misses_41(misses_41),
    .hits_41(hits_41)
  );

  initial begin
    // Load address trace from a file
    file = $fopen("addr_trace.txt", "r");
    i = 0;
    while (!$feof(file)) begin
      stat = $fscanf(file, "%d\n", face[i]);
      i = i + 1;
    end
    $fclose(file);

    // Generate cumulative addresses from the trace
    for (i = 0; i < `Length; i = i + 1) begin 
      if (i == 0) 
        actual[0] = face[0];
      else 
        actual[i] = actual[i-1] + face[i];
    end
  end

  // Generate clock signal
  always #5 clk_41 = ~clk_41;

  initial begin
    clk_41 = 0;
    rst_41 = 1;
    #10 rst_41 = 0; // Release reset after some time

    for (j = 0; j < `Length; j = j + 1) begin
      @(posedge clk_41) adder_41 = actual[j]; // Send address to the cache
    end

    @(posedge clk_41)
    m = misses_41;
    h = hits_41;
    hit_ratio_41 = (h / (m + h)) * per;
    $display("Hit Ratio = %7.2f%%, Cache Hits = %d, Total Simulation Addresses = %d", 
             hit_ratio_41, hits_41, (misses_41 + hits_41));
    
    $finish;
  end
endmodule
