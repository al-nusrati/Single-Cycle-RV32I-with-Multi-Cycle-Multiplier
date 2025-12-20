module mux_2to1 #(
    parameter DATA_WIDTH = 32
)(
    input  logic                     sel,  // Source: Control Unit
    input  logic [DATA_WIDTH-1:0]    in0,  // Source: Path A
    input  logic [DATA_WIDTH-1:0]    in1,  // Source: Path B
    output logic [DATA_WIDTH-1:0]    out   // Dest: ALU or Next Stage
);
    assign out = sel ? in1 : in0;
endmodule

// Explanation:
// A fundamental building block for data routing.
//
// 1. **ALU Source Mux**: Used to decide if the ALU's second operand comes from a Register (for `ADD`) 
//    or from the Immediate Generator (for `ADDI`).
// 2. **ALU A Mux**: Used to decide if the first operand is a Register or the PC (used for `AUIPC`).