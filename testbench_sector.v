module tb();
  reg clk_41, rst_41;
  reg [30:0] adder_41;
  reg [8:0]LS_41;
  reg [16:0] CS_41;
  reg [5:0] Assoc_41;
  
   wire [30:0] misses_41,hits_41;
  real hit_ratio_41,per = 100.00;
  real m,h;
  
  `define Length 1500000
	integer p,r,c;
    integer file,stat,out,i,j;
  reg signed [30:0] face[0:`Length-1];
  reg [30:0] actual[0:`Length-1];
  
  test t1(adder_41,clk_41, rst_41,misses_41,hits_41);

  initial begin
   file=$fopen("addr_trace.txt","r");
                   i=0;
            while (! $feof(file))
                begin
                   
                    stat=$fscanf(file,"%d\n",face[i]);
                            i=i+1;
                end
            $fclose(file);
    

    
         
    for(i=0;i<`Length;i=i+1) 
                begin 
                  if (i==0)  actual[0] = face[0];
                  else actual[i]=actual[i-1]+face[i];
                  			
                end
  end
 
  always  #5 clk_41 = ~clk_41;
   
  initial begin
           
    clk_41 = 0;
    rst_41 = 1;
    @(posedge clk_41) rst_41 = 0;

    for (j = 0 ; j<`Length ; j=j+1) begin
     
          
      @(posedge clk_41) adder_41 = actual[j];
      //$display("Address=%d",adder_41);
    end
  
   
    @(posedge clk_41)
    m=misses_41;
    h=hits_41;
   hit_ratio_41 = (h/(m+h))*per;
    $display("Hit Ratio=%7.2f Percentage, Cache Hits = %d, Total Simulation Addresses = %d",hit_ratio_41,hits_41,(misses_41 + hits_41));
    $finish;
  end
  
  
endmodule