# Makefile for Verilog Simulation

# Compiler and simulator settings
VLOG = iverilog
VOPT = vvp

# File names
SRC = sector_mapper_cache.v tb_sector_mapped_cache.v
OUT = simulation_output/sim_result

# Target: compile and simulate
all: compile simulate

# Compile the Verilog files
compile:
	$(VLOG) -o $(OUT) $(SRC)

# Run the simulation
simulate:
	$(VOPT) $(OUT)

# Clean up generated files
clean:
	rm -f $(OUT) simulation_output/*.vcd

.PHONY: all compile simulate clean
