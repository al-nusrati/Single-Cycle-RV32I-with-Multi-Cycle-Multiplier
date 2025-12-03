module mux_2to1 #(
    parameter DATA_WIDTH = 32
)(
    input  logic                     sel,       // select signal
    input  logic [DATA_WIDTH-1:0]    in0,       // input 0 from mux
    input  logic [DATA_WIDTH-1:0]    in1,       // input 1 from mux
    output logic [DATA_WIDTH-1:0]    out        // output towards alu
);
    assign out = sel ? in1 : in0;               // 2-to-1 mux logic
endmodule

// Explanation:
// This SystemVerilog module implements a 2-to-1 multiplexer (mux).
// It takes two DATA_WIDTH-bit inputs (in0 and in1) and a select signal (sel).
// Based on the value of sel, it outputs either in0 or in1 towards the ALU.