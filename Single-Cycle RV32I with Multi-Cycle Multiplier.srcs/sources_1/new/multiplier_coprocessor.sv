module multiplier_coprocessor (
    input         clk,
    input         reset,
    input         start,
    input  [31:0] a,
    input  [31:0] b,
    input  [2:0]  funct3,
    output reg [31:0] result,
    output reg       done,
    output reg       busy
);

    // State encoding - Vivado prefers binary encoding
    localparam [5:0] IDLE   = 6'b000000;
    localparam [5:0] BIT0   = 6'b000001;
    localparam [5:0] BIT1   = 6'b000010;
    localparam [5:0] BIT2   = 6'b000011;
    localparam [5:0] BIT3   = 6'b000100;
    localparam [5:0] BIT4   = 6'b000101;
    localparam [5:0] BIT5   = 6'b000110;
    localparam [5:0] BIT6   = 6'b000111;
    localparam [5:0] BIT7   = 6'b001000;
    localparam [5:0] BIT8   = 6'b001001;
    localparam [5:0] BIT9   = 6'b001010;
    localparam [5:0] BIT10  = 6'b001011;
    localparam [5:0] BIT11  = 6'b001100;
    localparam [5:0] BIT12  = 6'b001101;
    localparam [5:0] BIT13  = 6'b001110;
    localparam [5:0] BIT14  = 6'b001111;
    localparam [5:0] BIT15  = 6'b010000;
    localparam [5:0] BIT16  = 6'b010001;
    localparam [5:0] BIT17  = 6'b010010;
    localparam [5:0] BIT18  = 6'b010011;
    localparam [5:0] BIT19  = 6'b010100;
    localparam [5:0] BIT20  = 6'b010101;
    localparam [5:0] BIT21  = 6'b010110;
    localparam [5:0] BIT22  = 6'b010111;
    localparam [5:0] BIT23  = 6'b011000;
    localparam [5:0] BIT24  = 6'b011001;
    localparam [5:0] BIT25  = 6'b011010;
    localparam [5:0] BIT26  = 6'b011011;
    localparam [5:0] BIT27  = 6'b011100;
    localparam [5:0] BIT28  = 6'b011101;
    localparam [5:0] BIT29  = 6'b011110;
    localparam [5:0] BIT30  = 6'b011111;
    localparam [5:0] BIT31  = 6'b100000;
    localparam [5:0] FINISH = 6'b100001;
    
    reg [5:0] current_state, next_state;
    
    reg [31:0] multiplicand, multiplier;
    reg [63:0] product;
    reg [2:0]  funct3_reg;
    reg        sign_a, sign_b;
    reg        result_sign;
    
    reg [31:0] abs_a, abs_b;
    reg [63:0] signed_product;
    
    // Determine if operands should be treated as signed
    always @(*) begin
        case (funct3_reg)
            3'b000: begin sign_a = 1'b1; sign_b = 1'b1; end
            3'b001: begin sign_a = 1'b1; sign_b = 1'b1; end
            3'b010: begin sign_a = 1'b1; sign_b = 1'b0; end
            3'b011: begin sign_a = 1'b0; sign_b = 1'b0; end
            default: begin sign_a = 1'b1; sign_b = 1'b1; end
        endcase
    end
    
    // Calculate absolute values
    always @(*) begin
        // Absolute value for operand A
        if (sign_a && a[31]) begin
            if (a == 32'h80000000) begin
                abs_a = 32'h80000000;
            end else begin
                abs_a = ~a + 32'd1;
            end
        end else begin
            abs_a = a;
        end
        
        // Absolute value for operand B
        if (sign_b && b[31]) begin
            if (b == 32'h80000000) begin
                abs_b = 32'h80000000;
            end else begin
                abs_b = ~b + 32'd1;
            end
        end else begin
            abs_b = b;
        end
    end
    
    // Track result sign
    always @(*) begin
        result_sign = (sign_a && a[31]) ^ (sign_b && b[31]);
    end
    
    // State register
    always @(posedge clk or posedge reset) begin
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
            
            // 32-cycle sequential multiplication
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
                BIT13: if (multiplier[13]) product <= product + ({19'b0, multiplicand, 13'b0});
                BIT14: if (multiplier[14]) product <= product + ({18'b0, multiplicand, 14'b0});
                BIT15: if (multiplier[15]) product <= product + ({17'b0, multiplicand, 15'b0});
                BIT16: if (multiplier[16]) product <= product + ({16'b0, multiplicand, 16'b0});
                BIT17: if (multiplier[17]) product <= product + ({15'b0, multiplicand, 17'b0});
                BIT18: if (multiplier[18]) product <= product + ({14'b0, multiplicand, 18'b0});
                BIT19: if (multiplier[19]) product <= product + ({13'b0, multiplicand, 19'b0});
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
    always @(*) begin
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
    
    // Output signals
    always @(*) begin
        busy = (current_state != IDLE);
        done = (current_state == FINISH);
        
        // Apply sign correction
        signed_product = result_sign ? (~product + 64'd1) : product;
        
        // Select appropriate result
        case (funct3_reg)
            3'b000: result = signed_product[31:0];
            3'b001: result = signed_product[63:32];
            3'b010: result = signed_product[63:32];
            3'b011: result = product[63:32];
            default: result = product[31:0];
        endcase
    end

endmodule

// Explanation:
// This SystemVerilog module implements a multiplier coprocessor for a RISC-V CPU. It supports the multiplication instructions MUL, MULH, MULHSU, and MULHU.
// The module uses a sequential shift-and-add algorithm to perform multiplication over multiple clock cycles.
// It maintains a state machine to track the progress of the multiplication operation, transitioning through states for each bit of the multiplier.
// The module handles signed and unsigned multiplication based on the funct3 input, converting operands to absolute values as needed.
// The final result is adjusted for sign and selected according to the instruction type before being output.
