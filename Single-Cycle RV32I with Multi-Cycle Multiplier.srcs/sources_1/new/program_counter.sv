module program_counter (
    input  logic clk,              // Source: System Clock
    input  logic reset,            // Source: System Reset
    input  logic [31:0] pc_next,   // Source: Top Level (Next PC Logic/Mux)
    output logic [31:0] pc_address // Dest: Instruction Memory & PC+4 Adder
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
// The Program Counter (PC) is the heart of the fetch stage. It is a sequential register that holds 
// the 32-bit memory address of the *current* instruction being executed.
//
// 1. **Sequential Logic**: The use of `always_ff` ensures the PC only updates on the rising edge 
//    of the clock. This defines the processor's cycle time.
// 2. **Reset Behavior**: On a reset signal, it sets the address to 0x0, which is the entry point 
//    of the program in this architecture.
// 3. **Next Address**: The `pc_next` input is not just `PC + 4`. It comes from a multiplexer logic 
//    in the Top module that decides between:
//    - The next sequential instruction (PC + 4).
//    - A branch target (if a branch condition is met).
//    - A jump target (for JAL/JALR).
//    - The *current* PC (if `stall_cpu` is active due to the multiplier), effectively freezing the CPU.