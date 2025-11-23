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
        case (1'b1)
            (jump || jalr): write_data = pc_plus_4;
            lui: write_data = imm_out;
            auipc: write_data = alu_result;
            mem_to_reg: write_data = mem_data;
            default: write_data = alu_result;
        endcase
    end
endmodule