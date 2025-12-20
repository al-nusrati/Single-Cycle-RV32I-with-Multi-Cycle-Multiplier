module write_back_mux (
    input  logic        mem_to_reg, // Source: Control Unit
    input  logic        jump,       // Source: Control Unit
    input  logic        jalr,       // Source: Control Unit
    input  logic        lui,        // Source: Control Unit
    input  logic        auipc,      // Source: Control Unit
    input  logic [31:0] alu_result, // Source: ALU
    input  logic [31:0] mem_data,   // Source: Data Memory
    input  logic [31:0] pc_plus_4,  // Source: PC Logic
    input  logic [31:0] imm_out,    // Source: Immediate Gen
    input  logic [31:0] pc_address, // Source: PC
    output logic [31:0] write_data  // Dest: Register File
);
    always_comb begin
        if (lui) begin
            write_data = imm_out;
        end else if (auipc) begin
            write_data = pc_address + imm_out; // AUIPC needs PC + immediate
        end else if (jump || jalr) begin
            write_data = pc_plus_4;            // Jumps link the return address (PC+4)
        end else if (mem_to_reg) begin
            write_data = mem_data;             // Loads get data from Memory
        end else begin
            write_data = alu_result;           // R-type/I-type get data from ALU
        end
    end
endmodule

// Explanation:
// This module is the final decision maker in the pipeline. It determines what value gets 
// written back to the destination register (`rd`).
//
// 1. **Priority Logic**: It uses an if-else structure to prioritize inputs.
// 2. **Functionality**:
//    - `LUI`: Writes the immediate directly.
//    - `JAL/JALR`: Writes `PC+4` (Return Address) so functions can return.
//    - `LW`: Writes data read from memory.
//    - `ADD/SUB/MUL`: Writes the calculation result from the ALU.