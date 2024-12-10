# **M-way Set-Associative and Sector Mapped Cache in Verilog - Design and Testing**

### **Description**  
This project focuses on designing and testing advanced cache architectures using Verilog. The simulator evaluates the performance of **M-way Set-Associative Caches** and **Sector-Mapped Caches** by analyzing key parameters such as cache size, block size, associativity, and sector size. It provides insights into optimizing cache performance with configurable and fine-grained simulations.

---

## **How to Use**

### **Step 1: Install Required Packages**
Before running the simulations, ensure you have the following tools installed on your system:
1. **Icarus Verilog**:  
   Install Icarus Verilog for compiling and simulating Verilog code. Use the following command based on your operating system:
   - **Ubuntu/Debian**:  
     ```bash
     sudo apt update
     sudo apt install iverilog
     ```
     
   - **MacOS** (using Homebrew):  
     ```bash
     brew install icarus-verilog
     ```
     
   - **Windows**:  
     Download and install from the [official Icarus Verilog website](https://iverilog.fandom.com/wiki/Installation).

2. **GTKWave** (Optional):  
   Install GTKWave if you want to view waveforms generated during simulation:
   - **Ubuntu/Debian**:  
     ```bash
     sudo apt install gtkwave
     ```
   - **MacOS**:  
     ```bash
     brew install --cask gtkwave
     ```
   - **Windows**:  
     Download and install from the [official GTKWave website](http://gtkwave.sourceforge.net/).

### **Step 2: Simulate M-way Set-Associative Cache**
1. Compile the Verilog files using the following command:  
   ```bash
   iverilog -o sim_result_mway .\cache.v .\testbench.v
   ```
2. Run the simulation:  
   ```bash
   vvp .\sim_result_mway
   ```

### **Step 3: Simulate Sector-Mapped Cache**
1. Compile the Verilog files using the following command:  
   ```bash
   iverilog -o sim_result_sector .\cache_sector.v .\testbench_sector.v
   ```
2. Run the simulation:  
   ```bash
   vvp .\sim_result_sector
   ```

---

## **Parameters to be Tuned**
You can configure the following parameters in the Verilog files to experiment with cache performance:

- **Cache Size**:  
  ```verilog
  `define cache_size (1024*128) // Set cache size to 128 KB
  ```
- **Block (Line) Size**:  
  ```verilog
  `define line_size 16 // Set block size to 16 bytes
  ```
- **Associativity**:  
  ```verilog
  `define Associativity 32 // Fully associative cache (32-way)
  ```
- **Sector Size** (only for sector-mapped caches):  
  ```verilog
  `define sector_size 512 // Set sector size to 512 bytes
  ```

---

### **Contributors**
- [Kamlesh Kumar](https://github.com/kamlesh364)

---

### **Citation**

If you use this repository in your research or project, please cite it as follows:

```plaintext
@misc{Kumar2024CacheSimulation,
  author = {Kamlesh Kumar},
  title = {M-way Set-Associative and Sector Mapped Cache in Verilog - Design and Testing},
  year = {2024},
  howpublished = {\url{https://github.com/Kamlesh364/EE275_FinalProject_CacheSimulation}},
  note = {GitHub repository}
}
```
