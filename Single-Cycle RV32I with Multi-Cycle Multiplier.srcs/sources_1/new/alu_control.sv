// ==================== ALU CONTROL (FIXED) ====================
module alu_control (
    input  logic [1:0]  alu_op,
    input  logic [2:0]  funct3,
    input  logic [6:0]  funct7,
    input  logic [3:0]  mult_alu_control,
    input  logic        mult_instruction,
    input  logic [6:0]  opcode,  // CRITICAL: Need opcode to distinguish R-type vs I-type!
    output logic [3:0]  alu_control
);
    localparam ALU_AND    = 4'b0000;
    localparam ALU_OR     = 4'b0001;
    localparam ALU_ADD    = 4'b0010;
    localparam ALU_COPY_B = 4'b0011;
    localparam ALU_XOR    = 4'b0100;
    localparam ALU_SLL    = 4'b0101;
    localparam ALU_SUB    = 4'b0110;
    localparam ALU_SLT    = 4'b1000;
    localparam ALU_SLTU   = 4'b1001;
    localparam ALU_SRL    = 4'b1100;
    localparam ALU_SRA    = 4'b1101;
    
    always_comb begin
        // Check if it's a multiply instruction first
        if (mult_instruction && funct7[0] == 1'b1) begin
            alu_control = mult_alu_control;
        end else begin
            case (alu_op)
                2'b00: alu_control = ALU_ADD;        // Load/Store/AUIPC/JAL/JALR
                2'b01: alu_control = ALU_SUB;        // Branch
                2'b10: begin                         // R-type and I-type ALU
                    if (opcode == 7'b0110011) begin
                        // R-TYPE: Check funct7[5] to distinguish ADD/SUB
                        case (funct3)
                            3'b000: alu_control = funct7[5] ? ALU_SUB : ALU_ADD;  // ADD/SUB
                            3'b001: alu_control = ALU_SLL;   // SLL
                            3'b010: alu_control = ALU_SLT;   // SLT
                            3'b011: alu_control = ALU_SLTU;  // SLTU
                            3'b100: alu_control = ALU_XOR;   // XOR
                            3'b101: alu_control = funct7[5] ? ALU_SRA : ALU_SRL;  // SRL/SRA
                            3'b110: alu_control = ALU_OR;    // OR
                            3'b111: alu_control = ALU_AND;   // AND
                            default: alu_control = ALU_ADD;
                        endcase
                    end else begin
                        // I-TYPE: DON'T check funct7[5] for ADDI!
                        case (funct3)
                            3'b000: alu_control = ALU_ADD;   // ADDI (always ADD, never SUB!)
                            3'b001: alu_control = ALU_SLL;   // SLLI
                            3'b010: alu_control = ALU_SLT;   // SLTI
                            3'b011: alu_control = ALU_SLTU;  // SLTIU
                            3'b100: alu_control = ALU_XOR;   // XORI
                            3'b101: begin
                                // For I-type shifts, bit 30 (funct7[5]) distinguishes SRAI/SRLI
                                alu_control = funct7[5] ? ALU_SRA : ALU_SRL;
                            end
                            3'b110: alu_control = ALU_OR;    // ORI
                            3'b111: alu_control = ALU_AND;   // ANDI
                            default: alu_control = ALU_ADD;
                        endcase
                    end
                end
                2'b11: alu_control = ALU_COPY_B;     // LUI
                default: alu_control = ALU_ADD;
            endcase
        end
    end
endmodule


// Explanation:
// This SystemVerilog module implements the ALU control logic for a RISC-V CPU.
// It generates the appropriate ALU control signals based on the ALU operation code, funct3, and funct7 fields from the instruction.
// Additionally, it integrates control signals for multiplier operations when a multiply instruction is detected.
// The alu_control output provides the control signals to the ALU to perform the desired operation.
// The module supports standard ALU operations as well as multiplication operations by prioritizing multiplier control signals when applicable.