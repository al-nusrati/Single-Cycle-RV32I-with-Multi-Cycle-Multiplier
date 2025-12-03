module control (
    input  logic [6:0] opcode,               // opcode from instruction
    input  logic [2:0] funct3,               // funct3 field from instruction
    input  logic [6:0] funct7,               // funct7 field from instruction
    input  logic [3:0] mult_alu_control,     // control signals for multiplier ALU operations
    input  logic       mult_instruction,     // flag indicating a multiply instruction
    output logic       reg_write,            // register write enable
    output logic       alu_src,              // ALU source select
    output logic       mem_read,             // memory read enable
    output logic       mem_write,            // memory write enable
    output logic       mem_to_reg,           // memory to register select
    output logic       branch,               // branch instruction flag
    output logic       jump,                 // jump instruction flag
    output logic       jalr,                 // jump and link register instruction flag
    output logic       lui,                  // load upper immediate instruction flag 
    output logic       auipc,                // add upper immediate to PC instruction flag 
    output logic [3:0] alu_control
);

    logic [1:0] alu_op;
    logic       mult_instr_detected;

    control_unit main_ctrl (
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

    alu_control alu_ctrl (
        .alu_op(alu_op),
        .funct3(funct3),
        .funct7(funct7),
        .mult_alu_control(mult_alu_control),
        .mult_instruction(mult_instruction),
        .alu_control(alu_control)
    );

endmodule