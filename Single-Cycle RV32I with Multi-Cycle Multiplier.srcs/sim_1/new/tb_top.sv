module tb_top();

    logic clk;
    logic reset;
    integer log_file;
    integer cycle_count;
    
    // Instantiate the processor
    top uut (
        .clk(clk),
        .reset(reset)
    );
    
    // Clock generation - 10ns period (100 MHz)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // Test sequence with comprehensive logging
    initial begin
        // Open log file
        log_file = $fopen("processor_debug.txt", "w");
        cycle_count = 0;
        
        $fwrite(log_file, "========================================\n");
        $fwrite(log_file, "RV32IM Processor Simulation Debug Log\n");
        $fwrite(log_file, "========================================\n\n");
        
        // VCD dump for waveform analysis
        $dumpfile("simulation.vcd");
        $dumpvars(0, tb_top);
        
        // Reset sequence
        $fwrite(log_file, "Starting reset sequence...\n");
        reset = 1;
        #20;
        reset = 0;
        $fwrite(log_file, "Reset released at t=%0t\n\n", $time);
        
        // Run simulation
        #500000;
        
        // Final report
        $fwrite(log_file, "\n========================================\n");
        $fwrite(log_file, "SIMULATION COMPLETE\n");
        $fwrite(log_file, "========================================\n");
        $fwrite(log_file, "Total cycles: %0d\n", cycle_count);
        $fwrite(log_file, "Final PC: 0x%08h\n\n", uut.pc_address);
        
        $fwrite(log_file, "=== Final Register File State ===\n");
        for (int i = 0; i < 32; i++) begin
            if (uut.reg_file.registers[i] != 0) begin
                $fwrite(log_file, "x%-2d = 0x%08h (%0d)\n", 
                        i, uut.reg_file.registers[i], $signed(uut.reg_file.registers[i]));
            end
        end
        
        $fwrite(log_file, "\n=== Multiplication Verification ===\n");
        $fwrite(log_file, "x3 (multiplicand) = %0d\n", uut.reg_file.registers[3]);
        $fwrite(log_file, "x4 (multiplier)   = %0d\n", uut.reg_file.registers[4]);
        $fwrite(log_file, "x5 (result)       = %0d\n", uut.reg_file.registers[5]);
        $fwrite(log_file, "Expected result   = %0d\n", 
                uut.reg_file.registers[3] * uut.reg_file.registers[4]);
        
        if (uut.reg_file.registers[5] == (uut.reg_file.registers[3] * uut.reg_file.registers[4])) begin
            $fwrite(log_file, "✓ MULTIPLICATION TEST PASSED\n");
        end else begin
            $fwrite(log_file, "✗ MULTIPLICATION TEST FAILED\n");
        end
        
        $fclose(log_file);
        $display("Simulation complete. Check processor_debug.txt for details.");
        $finish;
    end
    
    // Cycle-by-cycle monitoring
    always @(posedge clk) begin
        if (!reset) begin
            cycle_count = cycle_count + 1;
            
            // Basic execution trace
            $fwrite(log_file, "[Cycle %4d | T=%0t] PC=0x%08h | Instr=0x%08h",
                    cycle_count, $time, uut.pc_address, uut.instruction);
            
            // Decode instruction type
            case (uut.instruction[6:0])
                7'b0010011: $fwrite(log_file, " (I-type)");
                7'b0110011: begin
                    if (uut.instruction[25]) 
                        $fwrite(log_file, " (M-ext)");
                    else 
                        $fwrite(log_file, " (R-type)");
                end
                7'b1100111: $fwrite(log_file, " (JALR)");
                default: $fwrite(log_file, " (Unknown)");
            endcase
            
            $fwrite(log_file, "\n");
            
            // Show control signals
            if (uut.reg_write) begin
                $fwrite(log_file, "        → Writing x%0d = 0x%08h (%0d)\n",
                        uut.instruction[11:7], uut.reg_write_data, $signed(uut.reg_write_data));
            end
            
            // Multiplier state tracking
            if (uut.mult_start) begin
                $fwrite(log_file, "        ⚡ MULTIPLY STARTED: %0d × %0d\n",
                        uut.data1, uut.data2);
            end
            
            if (uut.mult_busy) begin
                $fwrite(log_file, "        ⏳ MULT_BUSY | State=%0d | Product=0x%016h | Stalled=%b\n",
                        uut.multiplier.current_state, 
                        uut.multiplier.product,
                        uut.stall_cpu);
            end
            
            if (uut.mult_done) begin
                $fwrite(log_file, "        ✓ MULTIPLY DONE: Result = 0x%08h (%0d)\n",
                        uut.mult_result, $signed(uut.mult_result));
            end
            
            // Branch/Jump detection
            if (uut.branch_taken) begin
                $fwrite(log_file, "        → Branch taken to 0x%08h\n", uut.branch_target);
            end
            if (uut.jump || uut.jalr) begin
                $fwrite(log_file, "        → Jump to 0x%08h\n", uut.jump_target);
            end
        end
    end
    
    // Detect multiplier completion and verify
    always @(posedge uut.mult_done) begin
        $fwrite(log_file, "\n*** MULTIPLICATION COMPLETED ***\n");
        $fwrite(log_file, "Operand A (multiplicand): %0d (0x%08h)\n", 
                uut.multiplier.multiplicand, uut.multiplier.multiplicand);
        $fwrite(log_file, "Operand B (multiplier):   %0d (0x%08h)\n",
                uut.multiplier.multiplier, uut.multiplier.multiplier);
        $fwrite(log_file, "64-bit Product:           0x%016h\n", uut.multiplier.product);
        $fwrite(log_file, "Signed Product:           0x%016h\n", uut.multiplier.signed_product);
        $fwrite(log_file, "32-bit Result:            %0d (0x%08h)\n",
                uut.mult_result, uut.mult_result);
        $fwrite(log_file, "Expected (software):      %0d\n",
                uut.multiplier.multiplicand * uut.multiplier.multiplier);
        $fwrite(log_file, "funct3:                   %b\n", uut.multiplier.funct3_reg);
        $fwrite(log_file, "********************************\n\n");
    end

endmodule