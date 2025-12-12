module mux_2to1 #(
    parameter DATA_WIDTH = 32
)(
    input  logic                     sel,
    input  logic [DATA_WIDTH-1:0]    in0,
    input  logic [DATA_WIDTH-1:0]    in1,
    output logic [DATA_WIDTH-1:0]    out
);
    assign out = sel ? in1 : in0;
endmodule

// Explanation:
// This SystemVerilog module implements a 2-to-1 multiplexer (mux).
// It takes two DATA_WIDTH-bit inputs (in0 and in1) and a select signal (sel).
// Based on the value of sel, it outputs either in0 or in1 towards the ALU.