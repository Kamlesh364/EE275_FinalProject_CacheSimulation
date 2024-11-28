`define cache_size (1024*8)
`define line_size 32
`define sector_size 64 // new definition for sector size
`define Associativity 4

`define Index_bit (`Associativity==0)? 0: $clog2(`cache_size/(`line_size*`Associativity))
`define Offset_bit $clog2(`line_size)
`define Sector_Offset_Bit $clog2(`sector_size)
`define Tag_bit 31-(`Offset_bit+`Index_bit+`Sector_Offset_Bit)

module test(adder_41,clk_41, rst_41,misses_41,hits_41);
  input clk_41, rst_41;
  input [30:0] adder_41;
  output [30:0] misses_41,hits_41;
  
  reg [30:0] Num_Blocks_41,Num_Sets_41,misses_41,hits_41,cache_block_41,cache_set_41,set_index_41,Curr_Block_41,Curr_Count_41;
  reg data_present_41;
 
  integer i,j;
  integer k;
  
  parameter CS = `cache_size;
  parameter LS = `line_size;
  parameter SS = `sector_size; // sector size
  parameter Assoc = (`Associativity==0)? (CS/LS):`Associativity; 
  parameter Tbit = `Tag_bit;
  parameter Ob = `Offset_bit;
  parameter Ib = `Index_bit;
  parameter SOB = `Sector_Offset_Bit; // sector offset bit
  
  reg [(LS*8)-1:0] cache [0:(CS/LS) - 1];
  reg [Tbit-1:0] tag_array [0:(CS/LS) - 1]; // for all tags in cache
  reg valid_array [0:(CS/LS) - 1]; //0 - there is no data 1 - there is data
  
  // sector information
  reg [SOB-1:0] sector_offset [0:(CS/LS) - 1];
  
  reg [Tbit-1:0] tag; // for current tag
  
  reg [Assoc-1:0] counter [0:(CS/LS) - 1];
  
   
 initial begin
   hits_41 = 0;
   misses_41 = 0;
   Num_Blocks_41 = CS/LS;
   Num_Sets_41 = Num_Blocks_41/Assoc;
    
   for (k = 0; k <  Num_Blocks_41 ; k = k + 1)
		begin
          valid_array[k] = 0;
          tag_array[k] = 0;
          sector_offset[k] = 0; // initialize sector offset
		end
   for (j = 0; j <  Num_Sets_41 ; j = j + 1)
     for (k = 0; k <  Assoc ; k = k + 1)
       counter[(j*Assoc)+k] = k;
   
  end
 
   
  
  always@(posedge clk_41)begin
   
    cache_block_41 = (adder_41/LS)% Num_Blocks_41;
    cache_set_41 = ((adder_41/LS)% (Num_Blocks_41/Assoc));
    set_index_41 = cache_set_41*Assoc; //pointing at first block of current set
    data_present_41 = 0;
    
    tag = adder_41[30:(Ob+Ib+SOB)];
    
    for(i=0; i<Assoc; i=i+1) begin
      if ((valid_array [set_index_41+i] == 1) && (tag == tag_array[set_index_41+i])) begin
      hits_41 = hits_41+1;
      data_present_41 = 1;
      Curr_Block_41 = set_index_41+i;
      Curr_Count_41 = counter[Curr_Block_41];
     // $display("hits_41=%d",hits_41);
      end
    end
    
    if (data_present_41 == 0) begin
      misses_41 = misses_41+1;
    //  $display("misses_41=%d",misses_41);
      
      for(i=0; i<Assoc; i=i+1) begin
        if (counter[set_index_41+i]==0)begin
     	 	  tag_array[set_index_41+i] = tag;
      		valid_array [set_index_41+i] = 1;
          sector_offset[set_index_41+i] = adder_41[(Ob+Ib+SOB-1):(Ob+Ib)]; // store sector offset
          Curr_Block_41 = set_index_41+i;
          Curr_Count_41 = 0;
        end
      end
    end
    
      for(i=0; i<Assoc; i=i+1) begin // counter 
      
        if (counter[set_index_41+i]>Curr_Count_41)begin
          counter[set_index_41+i] = counter[set_index_41+i] - 1;
        end
        
        counter[Curr_Block_41] = Assoc - 1 ;
        
      end
      
  end
        
      

endmodule