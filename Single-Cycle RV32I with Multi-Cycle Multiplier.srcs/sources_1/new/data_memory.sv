module data_memory (
    input  logic clk,
    input  logic mem_read,                  // read enable signal
    input  logic mem_write,                 // write enable signal
    input  logic [2:0]  funct3,             // function 3 field to determine data size and sign extension - from instruction
    input  logic [31:0] address,            // memory address for read/write - from alu_result
    input  logic [31:0] write_data,         // data to write to memory - from data2
    output logic [31:0] read_data           // data read from memory - to write_back_mux
);
    logic [7:0] mem [0:1023];               // 1KB memory array  
    
    initial begin                           // initialize memory to zero
        for (int i = 0; i < 1024; i++) begin
            mem[i] = 8'b0;
        end
    end
    
    always_comb begin                       // combinational logic for reading memory
        if (mem_read) begin
            case (funct3)                   // determine read size and sign extension based on funct3 field
                3'b000: read_data = {{24{mem[address][7]}}, mem[address]};                          // LB - load byte with sign extension                               
                3'b001: read_data = {{16{mem[address+1][7]}}, mem[address+1], mem[address]};        // LH - load half-word with sign extension                          
                3'b010: read_data = {mem[address+3], mem[address+2], mem[address+1], mem[address]}; // LW - load word                       
                3'b100: read_data = {24'b0, mem[address]};                                          // LBU - load byte without sign extension                  
                3'b101: read_data = {16'b0, mem[address+1], mem[address]};                          // LHU - load half-word without sign extension                                            
                default: read_data = 32'b0;                                                         
            endcase
        end
        else begin
            read_data = 32'b0;
        end
    end
    
    always_ff @(posedge clk) begin                              // sequential logic for writing to memory
        if (mem_write) begin
            case (funct3)
                3'b000: mem[address] <= write_data[7:0];          // SB - store byte
                3'b001: begin                                     // SH - store half-word                                                 
                    mem[address]   <= write_data[7:0];            // lower byte
                    mem[address+1] <= write_data[15:8];           // upper byte
                end
                3'b010: begin                                     // SW - store word
                    mem[address]   <= write_data[7:0];            // lowest byte
                    mem[address+1] <= write_data[15:8];           // second byte
                    mem[address+2] <= write_data[23:16];          // third byte
                    mem[address+3] <= write_data[31:24];          // highest byte
                end
                default: ;                                   // do nothing for unsupported funct3                                   
            endcase
        end
    end
endmodule

// Explanation:
// This SystemVerilog module implements a data memory for a RISC-V CPU. It supports reading and writing data of different sizes (byte, half-word, word)
// based on the funct3 field from the instruction. The memory is 1KB in size, organized as an array of 8-bit bytes.
// The module uses combinational logic to read data from memory when the mem_read signal is highest, applying sign extension or zero extension as needed.
// The write operation occurs on the rising edge of the clock when the mem_write signal is high, storing data into memory according to the specified size.
// The module handles the following funct3 codes:
// LB (000), LH (001), LW (010), LBU (100), LHU (101) for loads
// SB (000), SH (001), SW (010) for stores
// The read_data output provides the data read from memory, while write_data is the data to be written to memory.
