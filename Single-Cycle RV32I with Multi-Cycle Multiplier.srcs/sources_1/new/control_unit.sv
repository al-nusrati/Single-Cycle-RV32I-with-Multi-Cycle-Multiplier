module control_unit (
    input  logic [6:0] opcode,
    input  logic [6:0] funct7,
    output logic       reg_write,
    output logic       alu_src,
    output logic       mem_read,
    output logic       mem_write,
    output logic       mem_to_reg,
    output logic       branch,
    output logic       jump,
    output logic       jalr,
    output logic       lui,
    output logic       auipc,
    output logic [1:0] alu_op,
    output logic       mult_instruction
);

    localparam OP_R_TYPE  = 7'b0110011;
    localparam OP_I_TYPE  = 7'b0010011;
    localparam OP_LOAD    = 7'b0000011;
    localparam OP_STORE   = 7'b0100011;
    localparam OP_BRANCH  = 7'b1100011;
    localparam OP_JAL     = 7'b1101111;
    localparam OP_JALR    = 7'b1100111;
    localparam OP_LUI     = 7'b0110111;
    localparam OP_AUIPC   = 7'b0010111;

    always_comb begin
        // Default values
        reg_write  = 1'b0;
        alu_src    = 1'b0;
        mem_read   = 1'b0;
        mem_write  = 1'b0;
        mem_to_reg = 1'b0;
        branch     = 1'b0;
        jump       = 1'b0;
        jalr       = 1'b0;
        lui        = 1'b0;
        auipc      = 1'b0;
        alu_op     = 2'b00;
        mult_instruction = 1'b0;
        
        case (opcode)
            OP_R_TYPE: begin
                reg_write  = 1'b1;
                alu_src    = 1'b0;
                alu_op     = 2'b10;
                // Check if multiply instruction (funct7[0] == 1)
                mult_instruction = funct7[0];
            end
            
            OP_I_TYPE: begin
                reg_write  = 1'b1;
                alu_src    = 1'b1;
                alu_op     = 2'b10;
            end
            
            OP_LOAD: begin
                reg_write  = 1'b1;
                alu_src    = 1'b1;
                mem_read   = 1'b1;
                mem_to_reg = 1'b1;
                alu_op     = 2'b00;
            end
            
            OP_STORE: begin
                alu_src    = 1'b1;
                mem_write  = 1'b1;
                alu_op     = 2'b00;
            end
            
            OP_BRANCH: begin
                branch     = 1'b1;
                alu_op     = 2'b01;
            end
            
            OP_JAL: begin
                reg_write  = 1'b1;
                jump       = 1'b1;
                alu_op     = 2'b00;
            end
            
            OP_JALR: begin
                reg_write  = 1'b1;
                alu_src    = 1'b1;
                jalr       = 1'b1;
                alu_op     = 2'b00;
            end
            
            OP_LUI: begin
                reg_write  = 1'b1;
                alu_src    = 1'b1;
                lui        = 1'b1;
                alu_op     = 2'b11;
            end
            
            OP_AUIPC: begin
                reg_write  = 1'b1;
                alu_src    = 1'b1;
                auipc      = 1'b1;
                alu_op     = 2'b00;
            end
            
            default: ; // Keep default values
        endcase
    end

endmodule



// Explanation:
// This SystemVerilog module implements the main control unit for a RISC-V CPU.
// It decodes the opcode from the instruction to generate various control signals needed for instruction execution.
// The control signals include register write enable, ALU source selection, memory read/write enables, branch/jump flags, and ALU operation codes.
// The module supports R-type, I-type, load, store, branch, jump (JAL, JALR), LUI, and AUIPC instructions.
// The mult_instruction output is set for R-type instructions to indicate multiply operations.
