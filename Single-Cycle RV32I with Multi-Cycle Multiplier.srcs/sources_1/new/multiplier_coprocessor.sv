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
    logic        result_sign;
    
    // ✅ DEEPSEEK FIX: MUL (3'b000) now uses signed×signed
    always_comb begin
        case (funct3_reg)
            3'b000: begin sign_a = 1'b1; sign_b = 1'b1; end  // MUL - FIXED: signed×signed
            3'b001: begin sign_a = 1'b1; sign_b = 1'b1; end  // MULH - signed×signed
            3'b010: begin sign_a = 1'b1; sign_b = 1'b0; end  // MULHSU - signed×unsigned
            3'b011: begin sign_a = 1'b0; sign_b = 1'b0; end  // MULHU - unsigned×unsigned
            default: begin sign_a = 1'b1; sign_b = 1'b1; end
        endcase
    end
    
    // Convert to absolute values for signed operands
    logic [31:0] abs_a, abs_b;
    assign abs_a = (sign_a && a[31]) ? (~a + 32'd1) : a;
    assign abs_b = (sign_b && b[31]) ? (~b + 32'd1) : b;
    
    // Track result sign
    assign result_sign = (sign_a && a[31]) ^ (sign_b && b[31]);
    
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
                multiplicand <= abs_a;
                multiplier <= abs_b;
                product <= 64'b0;
                funct3_reg <= funct3;
            end
            
            case (current_state)
                STEP1: begin
                    temp_product = 64'b0;
                    for (int i = 0; i < 8; i++) begin
                        if (multiplier[i]) begin
                            temp_product = temp_product + ({32'b0, multiplicand} << i);
                        end
                    end
                    product <= temp_product;
                end
                
                STEP2: begin
                    temp_product = product;
                    for (int i = 8; i < 16; i++) begin
                        if (multiplier[i]) begin
                            temp_product = temp_product + ({32'b0, multiplicand} << i);
                        end
                    end
                    product <= temp_product;
                end
                
                STEP3: begin
                    temp_product = product;
                    for (int i = 16; i < 24; i++) begin
                        if (multiplier[i]) begin
                            temp_product = temp_product + ({32'b0, multiplicand} << i);
                        end
                    end
                    product <= temp_product;
                end
                
                STEP4: begin
                    temp_product = product;
                    for (int i = 24; i < 32; i++) begin
                        if (multiplier[i]) begin
                            temp_product = temp_product + ({32'b0, multiplicand} << i);
                        end
                    end
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
    
    // Apply sign correction for signed results
    logic [63:0] signed_product;
    assign signed_product = result_sign ? (~product + 64'd1) : product;
    
    // ✅ MUL returns lower 32 bits (same for signed/unsigned after correct multiplication)
    always_comb begin
        case (funct3_reg)
            3'b000: result = product[31:0];           // MUL - lower 32 bits
            3'b001: result = signed_product[63:32];   // MULH - upper 32 bits with sign
            3'b010: result = signed_product[63:32];   // MULHSU - upper 32 bits with sign
            3'b011: result = product[63:32];          // MULHU - upper 32 bits unsigned
            default: result = product[31:0];
        endcase
    end

endmodule