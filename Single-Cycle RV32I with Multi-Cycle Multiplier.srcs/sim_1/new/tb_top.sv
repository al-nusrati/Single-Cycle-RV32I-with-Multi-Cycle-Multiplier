module tb_top();

    // Inputs
    reg clk;
    reg reset;
    
    // Instantiate the Unit Under Test (UUT)
    top uut (
        .clk(clk),
        .reset(reset)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;  // 100 MHz clock
    end
    
    // Test sequence
    initial begin
        // Initialize Inputs
        reset = 1;
        
        // Wait 100 ns for global reset to finish
        #100;
        
        // Release reset
        reset = 0;
        
        // Run simulation for enough cycles
        #1000;  // Run for 1000ns (100 cycles)
        
        // Check some results
        $display("Time = %0t: Simulation Complete", $time);
        $display("Final PC = 0x%08h", uut.pc_address);
        $display("Register x5 = %0d", uut.reg_file_inst.registers[5]);
        
        // Check if multiplication worked
        if (uut.reg_file_inst.registers[5] == 30) begin
            $display("✅ TEST PASSED: Multiplication correct (5 × 6 = 30)");
        end else begin
            $display("❌ TEST FAILED: x5 = %0d, expected 30", uut.reg_file_inst.registers[5]);
        end
        
        $finish;
    end
    
    // Monitor important signals
    always @(posedge clk) begin
        if (!reset) begin
            $display("Time = %0t: PC = 0x%08h, Instr = 0x%08h", 
                    $time, uut.pc_address, uut.instruction);
        end
    end

endmodule