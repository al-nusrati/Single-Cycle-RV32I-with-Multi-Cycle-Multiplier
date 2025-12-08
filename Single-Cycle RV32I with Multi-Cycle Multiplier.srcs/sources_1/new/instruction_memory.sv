module instruction_memory #(
    parameter DATA_WIDTH = 32,      // 32 bits per instruction
    parameter DEPTH = 8,            // 8 instructions
    parameter ADDR_WIDTH = 3        // 3 bits for addressing 8 instructions
)(
    input  logic [ADDR_WIDTH-1:0] address,          // instruction address from PC
    output logic [DATA_WIDTH-1:0] instruction       // fetched instruction to CPU
);
    logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];         // instruction memory array - 8 x 32 bits
    initial $readmemh("instructions.mem", mem);     // load instructions from file
    assign instruction = mem[address];              // output the instruction at the given address
endmodule

// Explanation:
// This SystemVerilog module implements an instruction memory for a RISC-V CPU.
// It stores a fixed set of instructions loaded from a file.
// The address input selects which instruction to output.
// The instruction output provides the instruction at the given address to the CPU.