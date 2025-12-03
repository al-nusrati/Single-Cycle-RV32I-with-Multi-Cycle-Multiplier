module alu_control (
    input  logic [1:0]  alu_op,             // ALU operation code from control unit 
    input  logic [2:0]  funct3,             // funct3 field from instruction
    input  logic [6:0]  funct7,             // funct7 field from instruction
    input  logic [3:0]  mult_alu_control,   // control signals for multiplier ALU operations
    input  logic        mult_instruction,   // flag indicating a multiply instruction
    output logic [3:0]  alu_control         // ALU control signals to ALU
);
    localparam ALU_AND   = 4'b0000;        
    localparam ALU_OR    = 4'b0001;
    localparam ALU_ADD   = 4'b0010;
    localparam ALU_COPY_B = 4'b0011;
    localparam ALU_XOR   = 4'b0100;
    localparam ALU_SLL   = 4'b0101;
    localparam ALU_SUB   = 4'b0110;
    localparam ALU_SLT   = 4'b1000;
    localparam ALU_SLTU  = 4'b1001;
    localparam ALU_SRL   = 4'b1100;
    localparam ALU_SRA   = 4'b1101;
    
    always_comb begin
        if (mult_instruction && mult_alu_control != 4'b0000) begin               // If it's a multiply instruction, use multiplier ALU control
            alu_control = mult_alu_control;                                      // Use multiplier ALU control signals 
        end else begin
            case (alu_op)
                2'b00: alu_control = ALU_ADD;                                    // Load/Store instructions
                2'b01: alu_control = ALU_SUB;                                    // Branch instructions
                2'b10: begin
                    case (funct3)
                        3'b000: alu_control = (funct7[5]) ? ALU_SUB : ALU_ADD;   // ADD/SUB
                        3'b001: alu_control = ALU_SLL;                           // SLL
                        3'b010: alu_control = ALU_SLT;                           // SLT
                        3'b011: alu_control = ALU_SLTU;                          // SLTU
                        3'b100: alu_control = ALU_XOR;                           // XOR
                        3'b101: alu_control = (funct7[5]) ? ALU_SRA : ALU_SRL;   // SRA/SRL
                        3'b110: alu_control = ALU_OR;                            // OR
                        3'b111: alu_control = ALU_AND;                           // AND
                        default: alu_control = ALU_ADD;                          // Default to ADD
                    endcase
                end
                2'b11: alu_control = ALU_COPY_B;                                 // For immediate instructions like LUI 
                default: alu_control = ALU_ADD;                                  // Default to ADD 
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