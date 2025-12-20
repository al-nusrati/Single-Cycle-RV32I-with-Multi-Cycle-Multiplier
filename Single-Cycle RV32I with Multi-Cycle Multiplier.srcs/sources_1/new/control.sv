module control (
    input  logic [6:0] opcode,           // Source: Instruction [6:0]
    input  logic [2:0] funct3,           // Source: Instruction [14:12]
    input  logic [6:0] funct7,           // Source: Instruction [31:25]
    input  logic [3:0] mult_alu_control, // Source: Multiplier Control
    input  logic       mult_instruction, // Source: Top Level Logic
    output logic       reg_write,        // Dest: Register File
    output logic       alu_src,          // Dest: ALU Source Mux
    output logic       mem_read,         // Dest: Data Memory
    output logic       mem_write,        // Dest: Data Memory
    output logic       mem_to_reg,       // Dest: Write-Back Mux
    output logic       branch,           // Dest: Branch Logic
    output logic       jump,             // Dest: PC Logic / WB Mux
    output logic       jalr,             // Dest: PC Logic / WB Mux
    output logic       lui,              // Dest: WB Mux
    output logic       auipc,            // Dest: WB Mux
    output logic [3:0] alu_control       // Dest: ALU
);

    logic [1:0] alu_op;
    logic       mult_instr_detected;

    control_unit main_ctrl (
        .opcode(opcode),
        .funct7(funct7),
        .reg_write(reg_write),
        .alu_src(alu_src),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .mem_to_reg(mem_to_reg),
        .branch(branch),
        .jump(jump),
        .jalr(jalr),
        .lui(lui),
        .auipc(auipc),
        .alu_op(alu_op),
        .mult_instruction(mult_instr_detected)
    );

    alu_control alu_ctrl (
    .alu_op(alu_op),
    .funct3(funct3),
    .funct7(funct7),
    .mult_alu_control(mult_alu_control),
    .mult_instruction(mult_instruction),
    .opcode(opcode),  
    .alu_control(alu_control)
);

endmodule

// Explanation:
// This is a structural wrapper module. It simplifies the Top module by grouping the 
// "Main Control Unit" and the "ALU Control Unit" into a single block.
// It ensures that the opcode decoding and the specific ALU operation decoding are 
// kept logically separate but physically packaged together.