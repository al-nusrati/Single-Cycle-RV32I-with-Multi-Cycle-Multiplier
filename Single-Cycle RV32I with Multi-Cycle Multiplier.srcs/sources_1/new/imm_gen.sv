module imm_gen (
    input  logic [31:0] instruction, // Source: Instruction Memory
    output logic [31:0] imm_out      // Dest: ALU Mux & Branch Target Logic
);
    logic [6:0] opcode;
    assign opcode = instruction[6:0];

    always_comb begin
        case (opcode)
            7'b0010011, 7'b0000011, 7'b1100111: 
                imm_out = {{20{instruction[31]}}, instruction[31:20]};
            7'b0100011: 
                imm_out = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};
            7'b1100011:
                imm_out = {{20{instruction[31]}}, instruction[7], instruction[30:25], instruction[11:8], 1'b0};
            7'b0110111, 7'b0010111:
                imm_out = {instruction[31:12], 12'b0};
            7'b1101111:
                imm_out = {{12{instruction[31]}}, instruction[19:12], instruction[20], instruction[30:21], 1'b0};
            default: 
                imm_out = {{20{instruction[31]}}, instruction[31:20]};
        endcase
    end
endmodule

// Explanation:
// Instructions often contain small constants (immediates). However, these bits are scattered 
// in different positions depending on the instruction type (I, S, B, U, J) to keep the register 
// specifiers (rs1, rs2, rd) in the same place.
//
// 1. **Sign Extension**: The module takes the scattered bits and rearranges them into a 32-bit 
//    integer. Crucially, it performs *sign extension* (replicating the MSB `instruction[31]`) 
//    so that negative constants remain negative in 32-bit representation.
// 2. **Combinational Logic**: This happens instantly, so the immediate is ready for the ALU 
//    in the same cycle as the instruction fetch.