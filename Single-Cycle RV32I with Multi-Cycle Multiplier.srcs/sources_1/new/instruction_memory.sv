module instruction_memory #(
    parameter DATA_WIDTH = 32,   
    parameter DEPTH = 256,
    parameter ADDR_WIDTH = 8
)(
    input  logic [ADDR_WIDTH-1:0] address,     // Source: Program Counter [9:2]
    output logic [DATA_WIDTH-1:0] instruction  // Dest: Control Unit, RegFile, ImmGen
);
    logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    
    initial begin
        $readmemh("instructions.mem", mem);
    end
    
    assign instruction = mem[address];
endmodule

// Explanation:
// This module acts as a Read-Only Memory (ROM) containing the program code.
//
// 1. **Word Alignment**: RISC-V instructions are 32 bits (4 bytes) wide. The PC increments by 4 
//    (0, 4, 8, 12...). However, the memory array is indexed by *word* (0, 1, 2, 3...). 
//    Therefore, in the Top module, we connect `pc_address[9:2]` to the address input. Dropping 
//    the bottom 2 bits effectively divides by 4.
// 2. **Initialization**: The `$readmemh` system task loads the hexadecimal machine code from 
//    "instructions.mem" into the simulation memory array at startup.
// 3. **Combinational Read**: The output `instruction` updates immediately when the `address` changes, 
//    allowing the Control Unit to decode the instruction within the same clock cycle.