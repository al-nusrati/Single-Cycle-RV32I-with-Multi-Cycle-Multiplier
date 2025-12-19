module multiplier_control (
    input  logic        clk,
    input  logic        reset,
    input  logic [6:0]  opcode,
    input  logic [2:0]  funct3,
    input  logic [6:0]  funct7,
    input  logic        mult_done,
    input  logic        mult_busy,
    output logic        mult_start,
    output logic        stall_cpu,
    output logic [3:0]  alu_control_out,
    output logic        mult_write_pending
);
    // ALU control codes for multiply operations
    localparam ALU_MUL    = 4'b1010;
    localparam ALU_MULH   = 4'b1011;
    localparam ALU_MULHSU = 4'b1110;
    localparam ALU_MULHU  = 4'b1111;
    localparam ALU_ADD    = 4'b0010;  // Default
    
    // FSM state encoding
    localparam [1:0] M_IDLE     = 2'b00;
    localparam [1:0] M_BUSY     = 2'b01;
    localparam [1:0] M_COMPLETE = 2'b10;
    
    logic [1:0] current_state, next_state;
    logic pending_write;
    logic mult_detected;
    logic [3:0] alu_control_reg;
    
    // Detect multiply instruction
    assign mult_detected = (opcode == 7'b0110011) && (funct7[0] == 1'b1);
    
    // State register
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            current_state <= M_IDLE;
            pending_write <= 1'b0;
            alu_control_reg <= ALU_ADD;
        end else begin
            current_state <= next_state;
            
            // Capture ALU control at the start of multiplication
            if (current_state == M_IDLE && mult_detected) begin
                case (funct3)
                    3'b000: alu_control_reg <= ALU_MUL;
                    3'b001: alu_control_reg <= ALU_MULH;
                    3'b010: alu_control_reg <= ALU_MULHSU;
                    3'b011: alu_control_reg <= ALU_MULHU;
                    default: alu_control_reg <= ALU_MUL;
                endcase
            end
            
            // Set pending_write flag when multiplication completes
            if (current_state == M_BUSY && mult_done) begin
                pending_write <= 1'b1;
            end else if (current_state == M_COMPLETE) begin
                pending_write <= 1'b0;
            end
        end
    end
    
    // Next state logic
    always_comb begin
        next_state = current_state;
        
        case (current_state)
            M_IDLE: begin
                if (mult_detected && !mult_busy) begin
                    next_state = M_BUSY;
                end
            end
            
            M_BUSY: begin
                if (mult_done) begin
                    next_state = M_COMPLETE;
                end
            end
            
            M_COMPLETE: begin
                next_state = M_IDLE;
            end
            
            default: next_state = M_IDLE;
        endcase
    end
    
    // Output logic
    // Start multiplication immediately when detected (same cycle)
    assign mult_start = (current_state == M_IDLE) && mult_detected;
    
    // Stall during BUSY and COMPLETE states (33 cycles total)
    assign stall_cpu = (current_state == M_BUSY) || (current_state == M_COMPLETE);
    
    // Write pending flag for register file
    assign mult_write_pending = pending_write;
    
    // ALU control output - maintain during multiplication
    assign alu_control_out = (mult_detected || current_state != M_IDLE) ? alu_control_reg : ALU_ADD;

endmodule