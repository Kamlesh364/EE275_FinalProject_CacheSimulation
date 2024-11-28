`define cache_size (1024 * 8)
`define line_size 32
`define Associativity 4
`define Sector_size 128 // Number of blocks per sector

`define Index_bit (`Associativity == 0) ? 0 : $clog2(`cache_size / (`line_size * `Associativity))
`define Offset_bit $clog2(`line_size)
`define Tag_bit 31 - (`Offset_bit + `Index_bit)

module test(adder_41, clk_41, rst_41, misses_41, hits_41);
  input clk_41, rst_41;
  input [30:0] adder_41;
  output reg [30:0] misses_41, hits_41;

  // Internal signals
  reg [30:0] Num_Blocks_41, Num_Sets_41, cache_block_41, cache_set_41, set_index_41, Curr_Block_41, Curr_Count_41;
  reg data_present_41;
  reg [30:0] Sectors_per_line;

  integer i, j, k;

  // Parameters
  parameter CS = `cache_size;
  parameter LS = `line_size;
  parameter Assoc = (`Associativity == 0) ? (CS / LS) : `Associativity;
  parameter Tbit = `Tag_bit;
  parameter Ob = `Offset_bit;
  parameter Ib = `Index_bit;
  parameter Sector_size = `Sector_size; // Number of blocks per sector

  // Cache memory and metadata
  reg [(LS * 8) - 1:0] cache [0:(CS / LS) - 1]; // Data array
  reg [Tbit - 1:0] tag_array [0:(CS / LS) - 1]; // Tag array
  reg valid_array [0:(CS / LS) - 1]; // Valid bits
  reg [Sector_size - 1:0] sector_valid [0:(CS / LS) - 1]; // Sector valid bits
  reg [Assoc - 1:0] counter [0:(CS / LS) - 1]; // LRU counters

  // Tag for the current address
  reg [Tbit - 1:0] tag;

  // Initialize cache
  initial begin
    hits_41 = 0;
    misses_41 = 0;
    Num_Blocks_41 = CS / LS;
    Num_Sets_41 = Num_Blocks_41 / Assoc;
    Sectors_per_line = LS / Sector_size;

    // Initialize valid bits and metadata
    for (k = 0; k < Num_Blocks_41; k = k + 1) begin
      valid_array[k] = 0;
      tag_array[k] = 0;
      sector_valid[k] = 0; // Clear all sectors
    end

    for (j = 0; j < Num_Sets_41; j = j + 1)
      for (k = 0; k < Assoc; k = k + 1)
        counter[(j * Assoc) + k] = k;
  end

  // Main logic
  always @(posedge clk_41 or posedge rst_41) begin
    if (rst_41) begin
      hits_41 <= 0;
      misses_41 <= 0;

      // Reset cache
      for (k = 0; k < Num_Blocks_41; k = k + 1) begin
        valid_array[k] <= 0;
        sector_valid[k] <= 0;
      end
    end else begin
      // Calculate indices and tags
      cache_block_41 = (adder_41 / LS) % Num_Blocks_41;
      cache_set_41 = (adder_41 / LS) % (Num_Blocks_41 / Assoc);
      set_index_41 = cache_set_41 * Assoc;
      data_present_41 = 0;
      tag = adder_41[30:(Ob + Ib)];

      // Check if the data is present
      for (i = 0; i < Assoc; i = i + 1) begin
        if ((valid_array[set_index_41 + i] == 1) && (tag == tag_array[set_index_41 + i])) begin
          // Check if the sector is valid
          if (sector_valid[set_index_41 + i][cache_block_41 % Sector_size] == 1) begin
            hits_41 = hits_41 + 1;
            data_present_41 = 1;
            Curr_Block_41 = set_index_41 + i;
            Curr_Count_41 = counter[Curr_Block_41];
          end
        end
      end

      // Handle cache miss
      if (!data_present_41) begin
        misses_41 = misses_41 + 1;

        // Find the least recently used block
        for (i = 0; i < Assoc; i = i + 1) begin
          if (counter[set_index_41 + i] == 0) begin
            tag_array[set_index_41 + i] = tag;
            valid_array[set_index_41 + i] = 1;
            sector_valid[set_index_41 + i] = 0; // Reset sector validity
            sector_valid[set_index_41 + i][cache_block_41 % Sector_size] = 1; // Mark sector as valid
            Curr_Block_41 = set_index_41 + i;
            Curr_Count_41 = 0;
          end
        end
      end

      // Update LRU counters
      for (i = 0; i < Assoc; i = i + 1) begin
        if (counter[set_index_41 + i] > Curr_Count_41)
          counter[set_index_41 + i] = counter[set_index_41 + i] - 1;

        counter[Curr_Block_41] = Assoc - 1;
      end
    end
  end
endmodule
