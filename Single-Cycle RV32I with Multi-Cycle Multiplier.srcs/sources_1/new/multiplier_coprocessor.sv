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

    typedef enum logic [5:0] {
        IDLE    = 6'd0,
        BIT0    = 6'd1,   BIT1    = 6'd2,   BIT2    = 6'd3,   BIT3    = 6'd4,
        BIT4    = 6'd5,   BIT5    = 6'd6,   BIT6    = 6'd7,   BIT7    = 6'd8,
        BIT8    = 6'd9,   BIT9    = 6'd10,  BIT10   = 6'd11,  BIT11   = 6'd12,
        BIT12   = 6'd13,  BIT13   = 6'd14,  BIT14   = 6'd15,  BIT15   = 6'd16,
        BIT16   = 6'd17,  BIT17   = 6'd18,  BIT18   = 6'd19,  BIT19   = 6'd20,
        BIT20   = 6'd21,  BIT21   = 6'd22,  BIT22   = 6'd23,  BIT23   = 6'd24,
        BIT24   = 6'd25,  BIT25   = 6'd26,  BIT26   = 6'd27,  BIT27   = 6'd28,
        BIT28   = 6'd29,  BIT29   = 6'd30,  BIT30   = 6'd31,  BIT31   = 6'd32,
        FINISH  = 6'd33
    } state_t;
    
    state_t current_state, next_state;
    
    logic [31:0] multiplicand, multiplier;
    logic [63:0] product;
    logic [2:0]  funct3_reg;
    logic        sign_a, sign_b;
    logic        result_sign;
    logic [31:0] a_reg, b_reg;
    
    // Sign determination
    always_comb begin
        case (funct3_reg)
            3'b000: begin sign_a = 1'b1; sign_b = 1'b1; end  // MUL
            3'b001: begin sign_a = 1'b1; sign_b = 1'b1; end  // MULH
            3'b010: begin sign_a = 1'b1; sign_b = 1'b0; end  // MULHSU
            3'b011: begin sign_a = 1'b0; sign_b = 1'b0; end  // MULHU
            default: begin sign_a = 1'b1; sign_b = 1'b1; end
        endcase
    end
    
    // Absolute value function
    function logic [31:0] get_abs(input logic [31:0] val, input logic is_signed);
        if (!is_signed) return val;
        if (val[31] == 1'b0) return val;
        if (val == 32'h80000000) return val;
        return ~val + 32'd1;
    endfunction
    
    // Absolute values
    logic [31:0] abs_a, abs_b;
    assign abs_a = get_abs(a_reg, sign_a);
    assign abs_b = get_abs(b_reg, sign_b);
    
    // Zero handling
    logic special_zero_case;
    assign special_zero_case = (a_reg == 32'h0) || (b_reg == 32'h0);
    
    // Result sign calculation
    logic a_neg, b_neg;
    assign a_neg = sign_a && a_reg[31] && !(a_reg == 32'h80000000 && special_zero_case);
    assign b_neg = sign_b && b_reg[31] && !(b_reg == 32'h80000000 && special_zero_case);
    assign result_sign = special_zero_case ? 1'b0 : (a_neg ^ b_neg);
    
    // State machine
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            current_state <= IDLE;
            a_reg <= 32'b0;
            b_reg <= 32'b0;
            multiplicand <= 32'b0;
            multiplier <= 32'b0;
            product <= 64'b0;
            funct3_reg <= 3'b0;
        end else begin
            current_state <= next_state;
            
            if (start && current_state == IDLE) begin
                a_reg <= a;
                b_reg <= b;
                multiplicand <= abs_a;
                multiplier <= abs_b;
                product <= 64'b0;
                funct3_reg <= funct3;
            end
            
            // Shift-and-add with CORRECT shift amounts
            case (current_state)
                BIT0:  if (multiplier[0])  product <= product + {32'b0, multiplicand};
                BIT1:  if (multiplier[1])  product <= product + ({31'b0, multiplicand, 1'b0});
                BIT2:  if (multiplier[2])  product <= product + ({30'b0, multiplicand, 2'b0});
                BIT3:  if (multiplier[3])  product <= product + ({29'b0, multiplicand, 3'b0});
                BIT4:  if (multiplier[4])  product <= product + ({28'b0, multiplicand, 4'b0});
                BIT5:  if (multiplier[5])  product <= product + ({27'b0, multiplicand, 5'b0});
                BIT6:  if (multiplier[6])  product <= product + ({26'b0, multiplicand, 6'b0});
                BIT7:  if (multiplier[7])  product <= product + ({25'b0, multiplicand, 7'b0});
                BIT8:  if (multiplier[8])  product <= product + ({24'b0, multiplicand, 8'b0});
                BIT9:  if (multiplier[9])  product <= product + ({23'b0, multiplicand, 9'b0});
                BIT10: if (multiplier[10]) product <= product + ({22'b0, multiplicand, 10'b0});
                BIT11: if (multiplier[11]) product <= product + ({21'b0, multiplicand, 11'b0});
                BIT12: if (multiplier[12]) product <= product + ({20'b0, multiplicand, 12'b0});
                BIT13: if (multiplier[13]) product <= product + ({19'b0, multiplicand, 13'b0});  // FIXED
                BIT14: if (multiplier[14]) product <= product + ({18'b0, multiplicand, 14'b0});  // FIXED
                BIT15: if (multiplier[15]) product <= product + ({17'b0, multiplicand, 15'b0});
                BIT16: if (multiplier[16]) product <= product + ({16'b0, multiplicand, 16'b0});
                BIT17: if (multiplier[17]) product <= product + ({15'b0, multiplicand, 17'b0});
                BIT18: if (multiplier[18]) product <= product + ({14'b0, multiplicand, 18'b0});
                BIT19: if (multiplier[19]) product <= product + ({13'b0, multiplicand, 19'b0});  // FIXED
                BIT20: if (multiplier[20]) product <= product + ({12'b0, multiplicand, 20'b0});
                BIT21: if (multiplier[21]) product <= product + ({11'b0, multiplicand, 21'b0});
                BIT22: if (multiplier[22]) product <= product + ({10'b0, multiplicand, 22'b0});
                BIT23: if (multiplier[23]) product <= product + ({9'b0, multiplicand, 23'b0});
                BIT24: if (multiplier[24]) product <= product + ({8'b0, multiplicand, 24'b0});
                BIT25: if (multiplier[25]) product <= product + ({7'b0, multiplicand, 25'b0});
                BIT26: if (multiplier[26]) product <= product + ({6'b0, multiplicand, 26'b0});
                BIT27: if (multiplier[27]) product <= product + ({5'b0, multiplicand, 27'b0});
                BIT28: if (multiplier[28]) product <= product + ({4'b0, multiplicand, 28'b0});
                BIT29: if (multiplier[29]) product <= product + ({3'b0, multiplicand, 29'b0});
                BIT30: if (multiplier[30]) product <= product + ({2'b0, multiplicand, 30'b0});
                BIT31: if (multiplier[31]) product <= product + ({1'b0, multiplicand, 31'b0});
                default: ;
            endcase
        end
    end
    
    // Next state logic
    always_comb begin
        next_state = current_state;
        case (current_state)
            IDLE:   if (start) next_state = BIT0;
            BIT0:   next_state = BIT1;
            BIT1:   next_state = BIT2;
            BIT2:   next_state = BIT3;
            BIT3:   next_state = BIT4;
            BIT4:   next_state = BIT5;
            BIT5:   next_state = BIT6;
            BIT6:   next_state = BIT7;
            BIT7:   next_state = BIT8;
            BIT8:   next_state = BIT9;
            BIT9:   next_state = BIT10;
            BIT10:  next_state = BIT11;
            BIT11:  next_state = BIT12;
            BIT12:  next_state = BIT13;
            BIT13:  next_state = BIT14;
            BIT14:  next_state = BIT15;
            BIT15:  next_state = BIT16;
            BIT16:  next_state = BIT17;
            BIT17:  next_state = BIT18;
            BIT18:  next_state = BIT19;
            BIT19:  next_state = BIT20;
            BIT20:  next_state = BIT21;
            BIT21:  next_state = BIT22;
            BIT22:  next_state = BIT23;
            BIT23:  next_state = BIT24;
            BIT24:  next_state = BIT25;
            BIT25:  next_state = BIT26;
            BIT26:  next_state = BIT27;
            BIT27:  next_state = BIT28;
            BIT28:  next_state = BIT29;
            BIT29:  next_state = BIT30;
            BIT30:  next_state = BIT31;
            BIT31:  next_state = FINISH;
            FINISH: next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end
    
    assign busy = (current_state != IDLE) && (current_state != FINISH);
    assign done = (current_state == FINISH);
    
    // Sign correction
    logic [63:0] signed_product;
    assign signed_product = result_sign ? (~product + 64'd1) : product;
    
    // Output selection
    logic [63:0] final_product;
    always_comb begin
        case (funct3_reg)
            3'b000: final_product = signed_product;  // MUL
            3'b001: final_product = signed_product;  // MULH
            3'b010: final_product = signed_product;  // MULHSU
            3'b011: final_product = product;         // MULHU
            default: final_product = product;
        endcase
    end
    
    always_comb begin
        case (funct3_reg)
            3'b000: result = final_product[31:0];   // MUL
            3'b001: result = final_product[63:32];  // MULH
            3'b010: result = final_product[63:32];  // MULHSU
            3'b011: result = final_product[63:32];  // MULHU
            default: result = final_product[31:0];
        endcase
    end

endmodule