module multiplier_coprocessor (
    input  logic        clk,
    input  logic        reset,
    input  logic        start,              // Start signal from multiplier_control
    input  logic [31:0] a,                  // Multiplicand (from rs1)
    input  logic [31:0] b,                  // Multiplier (from rs2 or immediate)
    input  logic [2:0]  funct3,             // MUL(000), MULH(001), MULHSU(010), MULHU(011)
    output logic [31:0] result,             // 32-bit result
    output logic        done,               // Multiplication complete flag
    output logic        busy                // Multiplier busy flag
);

    // State machine: 34 states total
    // IDLE(0) → BIT0(1) → BIT1(2) → ... → BIT31(32) → FINISH(33)
    typedef enum logic [5:0] {
        IDLE    = 6'd0,     // Waiting for start signal
        BIT0    = 6'd1,     // Process bit 0
        BIT1    = 6'd2,     // Process bit 1
        BIT2    = 6'd3,     // Process bit 2
        BIT3    = 6'd4,     // Process bit 3
        BIT4    = 6'd5,     // Process bit 4
        BIT5    = 6'd6,     // Process bit 5
        BIT6    = 6'd7,     // Process bit 6
        BIT7    = 6'd8,     // Process bit 7
        BIT8    = 6'd9,     // Process bit 8
        BIT9    = 6'd10,    // Process bit 9
        BIT10   = 6'd11,    // Process bit 10
        BIT11   = 6'd12,    // Process bit 11
        BIT12   = 6'd13,    // Process bit 12
        BIT13   = 6'd14,    // Process bit 13
        BIT14   = 6'd15,    // Process bit 14
        BIT15   = 6'd16,    // Process bit 15
        BIT16   = 6'd17,    // Process bit 16
        BIT17   = 6'd18,    // Process bit 17
        BIT18   = 6'd19,    // Process bit 18
        BIT19   = 6'd20,    // Process bit 19
        BIT20   = 6'd21,    // Process bit 20
        BIT21   = 6'd22,    // Process bit 21
        BIT22   = 6'd23,    // Process bit 22
        BIT23   = 6'd24,    // Process bit 23
        BIT24   = 6'd25,    // Process bit 24
        BIT25   = 6'd26,    // Process bit 25
        BIT26   = 6'd27,    // Process bit 26
        BIT27   = 6'd28,    // Process bit 27
        BIT28   = 6'd29,    // Process bit 28
        BIT29   = 6'd30,    // Process bit 29
        BIT30   = 6'd31,    // Process bit 30
        BIT31   = 6'd32,    // Process bit 31
        FINISH  = 6'd33     // Multiplication complete
    } state_t;
    
    state_t current_state, next_state;
    
    // Internal registers
    logic [31:0] multiplicand;      // Stored multiplicand (operand A)
    logic [31:0] multiplier;        // Stored multiplier (operand B)
    logic [63:0] product;           // 64-bit product accumulator
    logic [2:0]  funct3_reg;        // Stored funct3 for result selection
    logic [5:0]  bit_counter;       // Current bit being processed (0-31)
    
    // Sign handling signals
    logic        sign_a, sign_b;
    logic        result_sign;
    
    // Determine if operands should be treated as signed based on funct3
    always_comb begin
        case (funct3_reg)
            3'b000: begin sign_a = 1'b1; sign_b = 1'b1; end  // MUL - signed×signed
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
    
    // Track result sign (negative if operands have different signs)
    assign result_sign = (sign_a && a[31]) ^ (sign_b && b[31]);
    
    // ==================== STATE REGISTER ====================
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            current_state <= IDLE;
            multiplicand <= 32'b0;
            multiplier <= 32'b0;
            product <= 64'b0;
            funct3_reg <= 3'b0;
            bit_counter <= 6'd0;
        end else begin
            current_state <= next_state;
            
            // Load operands when multiplication starts
            if (start && current_state == IDLE) begin
                multiplicand <= abs_a;      // Use absolute values
                multiplier <= abs_b;
                product <= 64'b0;           // Clear product
                funct3_reg <= funct3;       // Store operation type
                bit_counter <= 6'd0;        // Reset bit counter
            end
            
            // Sequential shift-and-add algorithm
            // For each bit: if multiplier[bit] == 1, add shifted multiplicand
            case (current_state)
                BIT0:  begin
                    if (multiplier[0])  product <= product + {32'b0, multiplicand};
                    bit_counter <= 6'd1;
                end
                BIT1:  begin
                    if (multiplier[1])  product <= product + ({31'b0, multiplicand, 1'b0});
                    bit_counter <= 6'd2;
                end
                BIT2:  begin
                    if (multiplier[2])  product <= product + ({30'b0, multiplicand, 2'b0});
                    bit_counter <= 6'd3;
                end
                BIT3:  begin
                    if (multiplier[3])  product <= product + ({29'b0, multiplicand, 3'b0});
                    bit_counter <= 6'd4;
                end
                BIT4:  begin
                    if (multiplier[4])  product <= product + ({28'b0, multiplicand, 4'b0});
                    bit_counter <= 6'd5;
                end
                BIT5:  begin
                    if (multiplier[5])  product <= product + ({27'b0, multiplicand, 5'b0});
                    bit_counter <= 6'd6;
                end
                BIT6:  begin
                    if (multiplier[6])  product <= product + ({26'b0, multiplicand, 6'b0});
                    bit_counter <= 6'd7;
                end
                BIT7:  begin
                    if (multiplier[7])  product <= product + ({25'b0, multiplicand, 7'b0});
                    bit_counter <= 6'd8;
                end
                BIT8:  begin
                    if (multiplier[8])  product <= product + ({24'b0, multiplicand, 8'b0});
                    bit_counter <= 6'd9;
                end
                BIT9:  begin
                    if (multiplier[9])  product <= product + ({23'b0, multiplicand, 9'b0});
                    bit_counter <= 6'd10;
                end
                BIT10: begin
                    if (multiplier[10]) product <= product + ({22'b0, multiplicand, 10'b0});
                    bit_counter <= 6'd11;
                end
                BIT11: begin
                    if (multiplier[11]) product <= product + ({21'b0, multiplicand, 11'b0});
                    bit_counter <= 6'd12;
                end
                BIT12: begin
                    if (multiplier[12]) product <= product + ({20'b0, multiplicand, 12'b0});
                    bit_counter <= 6'd13;
                end
                BIT13: begin
                    if (multiplier[13]) product <= product + ({19'b0, multiplicand, 13'b0});
                    bit_counter <= 6'd14;
                end
                BIT14: begin
                    if (multiplier[14]) product <= product + ({18'b0, multiplicand, 14'b0});
                    bit_counter <= 6'd15;
                end
                BIT15: begin
                    if (multiplier[15]) product <= product + ({17'b0, multiplicand, 15'b0});
                    bit_counter <= 6'd16;
                end
                BIT16: begin
                    if (multiplier[16]) product <= product + ({16'b0, multiplicand, 16'b0});
                    bit_counter <= 6'd17;
                end
                BIT17: begin
                    if (multiplier[17]) product <= product + ({15'b0, multiplicand, 17'b0});
                    bit_counter <= 6'd18;
                end
                BIT18: begin
                    if (multiplier[18]) product <= product + ({14'b0, multiplicand, 18'b0});
                    bit_counter <= 6'd19;
                end
                BIT19: begin
                    if (multiplier[19]) product <= product + ({13'b0, multiplicand, 19'b0});
                    bit_counter <= 6'd20;
                end
                BIT20: begin
                    if (multiplier[20]) product <= product + ({12'b0, multiplicand, 20'b0});
                    bit_counter <= 6'd21;
                end
                BIT21: begin
                    if (multiplier[21]) product <= product + ({11'b0, multiplicand, 21'b0});
                    bit_counter <= 6'd22;
                end
                BIT22: begin
                    if (multiplier[22]) product <= product + ({10'b0, multiplicand, 22'b0});
                    bit_counter <= 6'd23;
                end
                BIT23: begin
                    if (multiplier[23]) product <= product + ({9'b0, multiplicand, 23'b0});
                    bit_counter <= 6'd24;
                end
                BIT24: begin
                    if (multiplier[24]) product <= product + ({8'b0, multiplicand, 24'b0});
                    bit_counter <= 6'd25;
                end
                BIT25: begin
                    if (multiplier[25]) product <= product + ({7'b0, multiplicand, 25'b0});
                    bit_counter <= 6'd26;
                end
                BIT26: begin
                    if (multiplier[26]) product <= product + ({6'b0, multiplicand, 26'b0});
                    bit_counter <= 6'd27;
                end
                BIT27: begin
                    if (multiplier[27]) product <= product + ({5'b0, multiplicand, 27'b0});
                    bit_counter <= 6'd28;
                end
                BIT28: begin
                    if (multiplier[28]) product <= product + ({4'b0, multiplicand, 28'b0});
                    bit_counter <= 6'd29;
                end
                BIT29: begin
                    if (multiplier[29]) product <= product + ({3'b0, multiplicand, 29'b0});
                    bit_counter <= 6'd30;
                end
                BIT30: begin
                    if (multiplier[30]) product <= product + ({2'b0, multiplicand, 30'b0});
                    bit_counter <= 6'd31;
                end
                BIT31: begin
                    if (multiplier[31]) product <= product + ({1'b0, multiplicand, 31'b0});
                    bit_counter <= 6'd32;
                end
                
                default: ;
            endcase
        end
    end
    
    // ==================== NEXT STATE LOGIC ====================
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
    
    // ==================== OUTPUT SIGNALS ====================
    assign busy = (current_state != IDLE);          // Busy when not in IDLE
    assign done = (current_state == FINISH);        // Done signal in FINISH state
    
    // Apply sign correction for signed results
    logic [63:0] signed_product;
    assign signed_product = result_sign ? (~product + 64'd1) : product;
    
    // Select appropriate result based on funct3
    always_comb begin
        case (funct3_reg)
            3'b000: result = signed_product[31:0];    // MUL - lower 32 bits with sign
            3'b001: result = signed_product[63:32];   // MULH - upper 32 bits with sign
            3'b010: result = signed_product[63:32];   // MULHSU - upper 32 bits with sign
            3'b011: result = product[63:32];          // MULHU - upper 32 bits unsigned
            default: result = product[31:0];
        endcase
    end

endmodule