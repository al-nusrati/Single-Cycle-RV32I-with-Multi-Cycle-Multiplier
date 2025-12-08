module program_counter (
    input  logic clk,
    input  logic reset,
    input  logic [31:0] pc_next,        // from top module
    output logic [31:0] pc_address     // to top module
);
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            pc_address <= 32'h0;
        end
        else begin
            pc_address <= pc_next;
        end
    end
endmodule

// Explanation:
// This SystemVerilog module implements a simple program counter (PC) for a RISC-V CPU.
// The PC holds the address of the next instruction to be executed.
// On the rising edge of the clock, if the reset signal is high, the PC is initialized to 0.
// Otherwise, it updates to the value of pc_next, which is provided by the top module.
// The pc_address output provides the current value of the program counter to the rest of the CPU.