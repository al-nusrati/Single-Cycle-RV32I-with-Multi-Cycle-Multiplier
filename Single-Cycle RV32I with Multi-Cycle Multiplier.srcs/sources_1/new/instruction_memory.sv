module instruction_memory #(
    parameter DATA_WIDTH = 32,
    parameter DEPTH = 256,
    parameter ADDR_WIDTH = 32
)(
    input  [ADDR_WIDTH-1:0] address,
    output reg [DATA_WIDTH-1:0] instruction
);
    
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    
    initial begin
        $readmemh("instructions.mem", mem);
    end
    
    always @(*) begin
        assign instruction = mem[address[7:0]];
    end
    
endmodule

// Explanation:
// This SystemVerilog module implements an instruction memory for a RISC-V CPU.
// It stores a fixed set of instructions loaded from a file.
// The address input selects which instruction to output.
// The instruction output provides the instruction at the given address to the CPU.