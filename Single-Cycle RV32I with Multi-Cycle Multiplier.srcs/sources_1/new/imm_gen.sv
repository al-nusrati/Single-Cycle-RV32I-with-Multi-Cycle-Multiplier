module imm_gen (
    input  logic [31:0] instruction,        // full 32-bit instruction from instruction memory
    output logic [31:0] imm_out             // generated immediate value towards alu
);
    logic [6:0] opcode;                     // opcode field from instruction    
    assign opcode = instruction[6:0];       // extract opcode from instruction

    always_comb begin
        case (opcode)
            // R-type instructions do not have immediate values
            7'b0010011, 7'b0000011, 7'b1100111: 
                imm_out = {{20{instruction[31]}}, instruction[31:20]};    

            // S-type instructions    
            7'b0100011: 
                imm_out = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};

            // B-type instructions
            7'b1100011:
                imm_out = {{20{instruction[31]}}, instruction[7], instruction[30:25], instruction[11:8], 1'b0};

            // U-type instructions
            7'b0110111, 7'b0010111:
                imm_out = {instruction[31:12], 12'b0};

            // J-type instructions
            7'b1101111:
                imm_out = {{12{instruction[31]}}, instruction[19:12], instruction[20], instruction[30:21], 1'b0};

            default: 
                imm_out = {{20{instruction[31]}}, instruction[31:20]};
        endcase
    end
endmodule

// Explanation:
// This SystemVerilog module generates immediate values for different RISC-V instruction types based on the opcode.
// It extracts the opcode from the instruction and uses combinational logic to create the appropriate immediate value 
// according to the instruction format (I-type, S-type, B-type, U-type, J-type).
// The generated immediate value is sign-extended to 32 bits where applicable.
// The module uses an always_comb block to ensure that the immediate value is updated whenever the instruction changes.
// The immediate value is output through the imm_out port for use in the ALU or other parts of the CPU.