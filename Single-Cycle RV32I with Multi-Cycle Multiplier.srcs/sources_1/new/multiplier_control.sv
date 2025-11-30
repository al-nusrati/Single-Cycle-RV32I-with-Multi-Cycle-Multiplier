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
    output logic [3:0]  alu_control_out
);
    localparam ALU_MUL    = 4'b1010;
    localparam ALU_MULH   = 4'b1011;
    localparam ALU_MULHSU = 4'b1110;
    localparam ALU_MULHU  = 4'b1111;
    
    typedef enum logic [1:0] {
        M_IDLE = 2'b00,
        M_STARTED = 2'b01,
        M_WAITING = 2'b10,
        M_COMPLETE = 2'b11
    } mult_ctrl_state_t;
    
    mult_ctrl_state_t current_state, next_state;
    
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            current_state <= M_IDLE;
        end else begin
            current_state <= next_state;
        end
    end
    
    always_comb begin
        next_state = current_state;
        
        case (current_state)
            M_IDLE: begin
                if (opcode == 7'b0110011 && funct7[0] == 1'b1) begin
                    next_state = M_STARTED;
                end
            end
            
            M_STARTED: begin
                next_state = M_WAITING;
            end
            
            M_WAITING: begin
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
    
    assign mult_start = (current_state == M_STARTED);
    
    // FIXED: Don't stall in M_COMPLETE - allows register write to happen
    // Stall only during M_STARTED (setup) and M_WAITING (computation)
    // M_COMPLETE allows write_enable to go high for register write
    assign stall_cpu = (current_state == M_STARTED || current_state == M_WAITING);
    
    always_comb begin
        if (opcode == 7'b0110011 && funct7[0] == 1'b1) begin
            case (funct3)
                3'b000: alu_control_out = ALU_MUL;
                3'b001: alu_control_out = ALU_MULH;
                3'b010: alu_control_out = ALU_MULHSU;
                3'b011: alu_control_out = ALU_MULHU;
                default: alu_control_out = ALU_MUL;
            endcase
        end else begin
            alu_control_out = 4'b0000;
        end
    end
endmodule