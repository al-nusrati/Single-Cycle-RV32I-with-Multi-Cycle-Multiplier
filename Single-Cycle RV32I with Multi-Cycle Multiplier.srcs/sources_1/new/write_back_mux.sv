module write_back_mux (
    input  logic        mem_to_reg,                      // select signal to choose data source for write-back
    input  logic        jump,                            // jump instruction flag
    input  logic        jalr,                            // jump and link register instruction flag
    input  logic        lui,                             // load upper immediate instruction flag
    input  logic        auipc,                           // add upper immediate to PC instruction flag
    input  logic [31:0] alu_result,                      // result from ALU operations
    input  logic [31:0] mem_data,                        // data read from memory
    input  logic [31:0] pc_plus_4,                       // PC + 4 value for jump instructions
    input  logic [31:0] imm_out,                         // immediate value output
    input  logic [31:0] pc_address,                      // current PC address
    output logic [31:0] write_data                       // data to write back to register file
);
    always_comb begin
        case (1'b1)                                      // 1 because only one signal will be high at a time
            (jump || jalr): write_data = pc_plus_4;      // for JAL and JALR, write PC + 4 to rd
            lui: write_data = imm_out;                   // for LUI, write immediate to rd
            auipc: write_data = alu_result;              // for AUIPC, write ALU result to rd
            mem_to_reg: write_data = mem_data;           // for load instructions, write memory data to rd
            default: write_data = alu_result;            // for other instructions, write ALU result to rd
        endcase
    end
endmodule

// Explanation:
// This SystemVerilog module implements a multiplexer for selecting the appropriate data to write back to the register file in a RISC-V CPU.
// The selection is based on control signals indicating the type of instruction being executed.
// The module considers jump instructions (JAL, JALR), LUI, AUIPC, load instructions, and other ALU operations.
// The write_data output provides the selected data to be written back to the register file.
// The always_comb block ensures that the output is updated combinationally based on the input control signals and data sources.
