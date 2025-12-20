module alu #(
    parameter DATA_WIDTH = 32
)(
    input  logic [DATA_WIDTH-1:0] a,           // Source: ALU Mux A
    input  logic [DATA_WIDTH-1:0] b,           // Source: ALU Mux B
    input  logic [3:0]            alu_control, // Source: ALU Control Unit
    input  logic [31:0]           mult_result, // Source: Multiplier Co-processor
    input  logic                  mult_done,   // Source: Multiplier Co-processor
    output logic [DATA_WIDTH-1:0] result,      // Dest: Data Memory & Write-Back Mux
    output logic                  zero         // Dest: Branch Logic
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
    localparam ALU_MULHSU = 4'b1110;
    localparam ALU_MULHU  = 4'b1111;
    localparam ALU_SRL   = 4'b1100;
    localparam ALU_SRA   = 4'b1101;
    
    // Detect if current operation is a multiply
    logic is_multiply_op;
    assign is_multiply_op = (alu_control == ALU_MUL) || (alu_control == ALU_MULH) || (alu_control == ALU_MULHSU) || (alu_control == ALU_MULHU);
    
    always_comb begin
        // For multiply operations: ONLY output result when mult_done is true
        // Otherwise output 0 (prevents corrupting registers)
        if (is_multiply_op) begin
            if (mult_done) begin
                result = mult_result;      // Output multiplier result
            end else begin
                result = 32'b0;           // Output 0 during multiplication
            end
        end else begin
            // Regular ALU operations
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
                default:    result = a + b;
            endcase
        end
    end
    
    // Zero flag: For non-multiply operations only
    assign zero = !is_multiply_op ? (a == b) : 1'b0;
endmodule

// Explanation:
// The ALU is the computational engine.
//
// 1. **Standard Operations**: It performs single-cycle arithmetic (ADD, SUB) and logic (AND, OR, XOR, Shifts).
// 2. **Co-Processor Integration**: This is a unique feature of this design. The ALU acts as a 
//    "gateway" for the Multiplier.
//    - If the operation is a Multiply, the ALU ignores its own adder logic.
//    - It waits for the `mult_done` signal.
//    - While waiting, it outputs 0 (safe value).
//    - When `mult_done` arrives, it passes `mult_result` to the output.
//    This allows the rest of the pipeline (Memory, Writeback) to treat the Multiplier result 
//    just like any other ALU result.