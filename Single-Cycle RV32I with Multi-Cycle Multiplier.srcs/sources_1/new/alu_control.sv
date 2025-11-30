module alu_control_enhanced (
    input  logic [1:0]  alu_op,
    input  logic [2:0]  funct3,
    input  logic [6:0]  funct7,
    input  logic [3:0]  mult_alu_control,
    input  logic        mult_instruction,
    output logic [3:0]  alu_control
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
        if (mult_instruction && mult_alu_control != 4'b0000) begin
            alu_control = mult_alu_control;
        end else begin
            case (alu_op)
                2'b00: alu_control = ALU_ADD;
                2'b01: alu_control = ALU_SUB;
                2'b10: begin
                    case (funct3)
                        3'b000: alu_control = (funct7[5]) ? ALU_SUB : ALU_ADD;
                        3'b001: alu_control = ALU_SLL;
                        3'b010: alu_control = ALU_SLT;
                        3'b011: alu_control = ALU_SLTU;
                        3'b100: alu_control = ALU_XOR;
                        3'b101: alu_control = (funct7[5]) ? ALU_SRA : ALU_SRL;
                        3'b110: alu_control = ALU_OR;
                        3'b111: alu_control = ALU_AND;
                        default: alu_control = ALU_ADD;
                    endcase
                end
                2'b11: alu_control = ALU_COPY_B;
                default: alu_control = ALU_ADD;
            endcase
        end
    end
endmodule