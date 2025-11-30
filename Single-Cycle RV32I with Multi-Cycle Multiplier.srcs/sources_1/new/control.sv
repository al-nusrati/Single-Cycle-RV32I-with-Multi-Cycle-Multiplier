module control_enhanced (
    input  logic [6:0] opcode,
    input  logic [2:0] funct3,
    input  logic [6:0] funct7,
    input  logic [3:0] mult_alu_control,
    input  logic       mult_instruction,
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
    output logic [3:0] alu_control
);

    logic [1:0] alu_op;
    logic       mult_instr_detected;

    control_unit_enhanced main_ctrl (
        .opcode(opcode),
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

    alu_control_enhanced alu_ctrl (
        .alu_op(alu_op),
        .funct3(funct3),
        .funct7(funct7),
        .mult_alu_control(mult_alu_control),
        .mult_instruction(mult_instruction),
        .alu_control(alu_control)
    );

endmodule