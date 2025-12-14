module write_back_mux (
    input  logic        mem_to_reg,
    input  logic        jump,
    input  logic        jalr,
    input  logic        lui,
    input  logic        auipc,
    input  logic [31:0] alu_result,
    input  logic [31:0] mem_data,
    input  logic [31:0] pc_plus_4,
    input  logic [31:0] imm_out,
    input  logic [31:0] pc_address,
    output logic [31:0] write_data
);
    always_comb begin
        if (lui) begin
            write_data = imm_out;
        end else if (auipc) begin
            write_data = pc_address + imm_out; // AUIPC needs PC + immediate
        end else if (jump || jalr) begin
            write_data = pc_plus_4;
        end else if (mem_to_reg) begin
            write_data = mem_data;
        end else begin
            write_data = alu_result;
        end
    end
endmodule

// Explanation:
// This SystemVerilog module implements a multiplexer for selecting the appropriate data to write back to the register file in a RISC-V CPU.
// The selection is based on control signals indicating the type of instruction being executed.
// The module considers jump instructions (JAL, JALR), LUI, AUIPC, load instructions, and other ALU operations.
// The write_data output provides the selected data to be written back to the register file.
// The always_comb block ensures that the output is updated combinationally based on the input control signals and data sources.
