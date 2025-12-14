module instruction_memory #(
    parameter DATA_WIDTH = 32,
    parameter DEPTH = 256,
    parameter ADDR_WIDTH = 8
)(
    input  logic [ADDR_WIDTH-1:0] address,
    output logic [DATA_WIDTH-1:0] instruction
);
    logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    
    initial begin
        $readmemh("instructions.mem", mem);
    end
    
    assign instruction = mem[address];
endmodule

// Explanation:
// This SystemVerilog module implements an instruction memory for a RISC-V CPU.
// It stores a fixed set of instructions loaded from a file.
// The address input selects which instruction to output.
// The instruction output provides the instruction at the given address to the CPU.