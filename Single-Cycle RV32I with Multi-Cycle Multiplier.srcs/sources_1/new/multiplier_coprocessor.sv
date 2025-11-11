module multiplier_coprocessor (
    input  logic        clk,
    input  logic        reset,
    input  logic        start,
    input  logic [31:0] a,
    input  logic [31:0] b,
    input  logic [2:0]  funct3,
    output logic [31:0] result,
    output logic        done,
    output logic        busy
);

    typedef enum logic [2:0] {
        IDLE    = 3'b000,
        STEP1   = 3'b001,
        STEP2   = 3'b010,
        STEP3   = 3'b011,
        STEP4   = 3'b100,
        FINISH  = 3'b101
    } state_t;
    
    state_t current_state, next_state;
    
    logic [31:0] multiplicand, multiplier;
    logic [63:0] product;
    logic [63:0] temp_product;
    logic [2:0]  funct3_reg;
    logic        sign_a, sign_b;
    
    always_comb begin
        case (funct3_reg)
            3'b000: begin sign_a = 1'b1; sign_b = 1'b1; end
            3'b001: begin sign_a = 1'b1; sign_b = 1'b1; end
            3'b010: begin sign_a = 1'b1; sign_b = 1'b0; end
            3'b011: begin sign_a = 1'b0; sign_b = 1'b0; end
            default: begin sign_a = 1'b1; sign_b = 1'b1; end
        endcase
    end
    
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            current_state <= IDLE;
            multiplicand <= 32'b0;
            multiplier <= 32'b0;
            product <= 64'b0;
            funct3_reg <= 3'b0;
        end else begin
            current_state <= next_state;
            
            if (start && current_state == IDLE) begin
                multiplicand <= (sign_a) ? $signed(a) : a;
                multiplier <= (sign_b) ? $signed(b) : b;
                product <= 64'b0;
                funct3_reg <= funct3;
            end
            
            case (current_state)
                STEP1: begin
                    if (multiplier[0]) 
                        product <= {32'b0, multiplicand};
                    else
                        product <= 64'b0;
                end
                STEP2: begin
                    temp_product = product;
                    if (multiplier[1])
                        temp_product = temp_product + ({31'b0, multiplicand, 1'b0});
                    product <= temp_product;
                end
                STEP3: begin
                    temp_product = product;
                    if (multiplier[2])
                        temp_product = temp_product + ({30'b0, multiplicand, 2'b0});
                    product <= temp_product;
                end
                STEP4: begin
                    temp_product = product;
                    if (multiplier[3])
                        temp_product = temp_product + ({29'b0, multiplicand, 3'b0});
                    product <= temp_product;
                end
                default: ;
            endcase
        end
    end
    
    always_comb begin
        next_state = current_state;
        case (current_state)
            IDLE:   if (start) next_state = STEP1;
            STEP1:  next_state = STEP2;
            STEP2:  next_state = STEP3;
            STEP3:  next_state = STEP4;
            STEP4:  next_state = FINISH;
            FINISH: next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end
    
    assign busy = (current_state != IDLE);
    assign done = (current_state == FINISH);
    
    always_comb begin
        case (funct3_reg)
            3'b000: result = product[31:0];
            3'b001: result = product[63:32];
            3'b010: result = product[63:32];
            3'b011: result = product[63:32];
            default: result = product[31:0];
        endcase
    end

endmodule