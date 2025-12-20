module control_unit (
    input  logic [6:0] opcode,           // Source: Instruction [6:0]
    input  logic [6:0] funct7,           // Source: Instruction [31:25]
    output logic       reg_write,        // Dest: Register File
    output logic       alu_src,          // Dest: ALU Source Mux
    output logic       mem_read,         // Dest: Data Memory
    output logic       mem_write,        // Dest: Data Memory
    output logic       mem_to_reg,       // Dest: Write-Back Mux
    output logic       branch,           // Dest: Branch Logic
    output logic       jump,             // Dest: PC Logic
    output logic       jalr,             // Dest: PC Logic
    output logic       lui,              // Dest: Write-Back Mux
    output logic       auipc,            // Dest: Write-Back Mux
    output logic [1:0] alu_op,           // Dest: ALU Control
    output logic       mult_instruction  // Dest: ALU Control & Multiplier Control
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
// This is the "Brain" of the processor. It looks at the Opcode (7 bits) and decides the 
// overall strategy for the instruction.
//
// 1. **Signal Generation**:
//    - If Opcode is Load (`LW`), it sets `mem_read` and `mem_to_reg`.
//    - If Opcode is Store (`SW`), it sets `mem_write`.
//    - If Opcode is Branch (`BEQ`), it sets `branch`.
// 2. **ALU Op**: It generates a 2-bit `alu_op` code that tells the ALU Control unit 
//    "Check the funct3/funct7 bits" (for R-type) or "Just Add" (for Loads/Stores).
// 3. **Multiply Detection**: It checks `funct7` bit 0 to flag if an R-type instruction 
//    is actually a Multiply (M-extension), signaling the Multiplier Control to take over.