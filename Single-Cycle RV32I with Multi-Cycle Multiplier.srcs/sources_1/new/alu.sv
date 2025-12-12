module alu #(
    parameter DATA_WIDTH = 32
)(
    input  logic [DATA_WIDTH-1:0] a,
    input  logic [DATA_WIDTH-1:0] b,
    input  logic [3:0]            alu_control,
    input  logic [31:0]           mult_result,
    input  logic                  mult_done,
    output logic [DATA_WIDTH-1:0] result,
    output logic                  zero
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
    localparam ALU_MUL    = 4'b1010;
    localparam ALU_MULH   = 4'b1011;
    localparam ALU_SRL   = 4'b1100;
    localparam ALU_SRA   = 4'b1101;
    localparam ALU_MULHSU = 4'b1110;
    localparam ALU_MULHU  = 4'b1111;
    
    always_comb begin
        case (alu_control)
            ALU_ADD:    result = a + b;
            ALU_SUB:    result = a - b;
            ALU_AND:    result = a & b;
            ALU_OR:     result = a | b;
            ALU_XOR:    result = a ^ b;
            ALU_SLL:    result = a << b[4:0];
            ALU_SRL:    result = a >> b[4:0];
            ALU_SRA:    result = $signed(a) >>> b[4:0];
            ALU_SLT:    result = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0;
            ALU_SLTU:   result = (a < b) ? 32'd1 : 32'd0;
            ALU_COPY_B: result = b;
            ALU_MUL:    result = mult_done ? mult_result : 32'b0;
            ALU_MULH:   result = mult_done ? mult_result : 32'b0;
            ALU_MULHSU: result = mult_done ? mult_result : 32'b0;
            ALU_MULHU:  result = mult_done ? mult_result : 32'b0;
            default:    result = a + b;
        endcase
    end
    
    assign zero = (alu_control != ALU_MUL && 
                alu_control != ALU_MULH && 
                alu_control != ALU_MULHSU && 
                alu_control != ALU_MULHU) ? (a == b) : 1'b0;
endmodule

// Explanation:
// This ALU module performs various arithmetic and logical operations based on the alu_control signal.
// It supports standard operations like addition, subtraction, bitwise AND/OR/XOR, shifts, and set-less-than comparisons.
// Additionally, it integrates multiplication operations by accepting results from a separate multiplier coprocessor.
// The Zero flag is set when the two inputs are equal, but only for non-multiplier operations.
// The module uses combinational logic to compute the result based on the selected operation.
// combinational logic: ALU operations based on alu_control signal 
// multiplication operations: integrates results from multiplier coprocessor
// zero flag: indicates if inputs are equal for non-multiplier operations
// ALU_COPY_B: passes input b directly to output, it is needed because some instructions require the second operand to be used as-is like in load/store instructions and immediate arithmetic instructions.
// ALU_MUL, ALU_MULH, ALU_MULHSU, ALU_MULHU: handle multiplication results when the multiplication operation is complete.
// TOTAL INSTRUCTIONS: 16 - standard ALU ops + 4 multiplication ops