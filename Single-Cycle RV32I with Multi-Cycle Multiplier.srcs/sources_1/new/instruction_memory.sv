module instruction_memory #(
    parameter DATA_WIDTH = 32,
    parameter DEPTH = 8,
    parameter ADDR_WIDTH = 3
)(
    input  logic [ADDR_WIDTH-1:0] address,
    output logic [DATA_WIDTH-1:0] instruction
);
    logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    initial $readmemh("instructions.mem", mem);
    assign instruction = mem[address];
endmodule