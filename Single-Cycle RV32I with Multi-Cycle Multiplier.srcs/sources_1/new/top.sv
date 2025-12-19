module top #(
    parameter DATA_WIDTH = 32,
    parameter ADDRESS_WIDTH = 32
)(
    input  logic clk,
    input  logic reset
);

    // Internal signals
    logic [31:0] pc_address, pc_next, pc_plus_4;
    logic [31:0] instruction;
    logic [31:0] imm_out;
    logic [31:0] data1, data2;
    logic [31:0] alu_operand2, alu_operand_a;
    logic [31:0] alu_result;
    logic [31:0] mem_read_data;
    logic [31:0] reg_write_data;
    logic [31:0] branch_target, jump_target;
    logic [3:0]  alu_control;
    logic        reg_write, alu_src, mem_read, mem_write, mem_to_reg, branch, zero;
    logic        jump, jalr, lui, auipc;
    logic        branch_taken;
    
    // Multiplier signals
    logic [31:0] mult_result;
    logic        mult_start, mult_done, mult_busy;
    logic        stall_cpu;
    logic [3:0]  mult_alu_control;
    logic        mult_instruction;
    logic        mult_write_pending;
    
    // PC calculations
    assign pc_plus_4 = pc_address + 4;
    assign branch_target = pc_address + imm_out;
    assign jump_target = jalr ? ((data1 + imm_out) & ~32'b1) : (pc_address + imm_out);
    
    // PC next logic with stall support
    assign pc_next = stall_cpu ? pc_address : 
                    (branch_taken ? branch_target : 
                    (jump || jalr ? jump_target : pc_plus_4));
    
    // Program Counter
    program_counter pc (
        .clk(clk),
        .reset(reset),
        .pc_next(pc_next),
        .pc_address(pc_address)
    );
    
    // Instruction Memory - FIXED: Use word-aligned address
    instruction_memory imem (
        .address(pc_address[9:2]),  // Word addressing for 256 instructions
        .instruction(instruction)
    );
    
    // Register File with special multiplier write enable
    // CRITICAL FIX: During multiplication, we should NOT write anything
    // until mult_write_pending is set by the multiplier control
    register_file reg_file (
        .clk(clk),
        .reset(reset),
        .write_enable((reg_write && !stall_cpu) || mult_write_pending),
        .rs1(instruction[19:15]),
        .rs2(instruction[24:20]),
        .rd(instruction[11:7]),
        .write_data(reg_write_data),
        .out_rs1(data1),
        .out_rs2(data2)
    );
    
    // Immediate Generator
    imm_gen imm_gen (
        .instruction(instruction),
        .imm_out(imm_out)
    );
    
    // ALU Operand A Mux (for AUIPC)
    mux_2to1 alu_a_mux (
        .sel(auipc),
        .in0(data1),
        .in1(pc_address),
        .out(alu_operand_a)
    );
    
    // ALU Source Mux (Operand B)
    mux_2to1 alu_src_mux (
        .sel(alu_src),
        .in0(data2),
        .in1(imm_out),
        .out(alu_operand2)
    );
    
    // ALU with multiplier interface - FIXED: Will output 'a' during multiplication
    // instead of 0 to prevent corrupting registers
    alu alu (
        .a(alu_operand_a),
        .b(alu_operand2),
        .alu_control(alu_control),
        .mult_result(mult_result),
        .mult_done(mult_done),
        .result(alu_result),
        .zero(zero)
    );
    
    // 32-Cycle Multiplier Co-Processor - FIXED: Uses data2 (register) not alu_operand2
    // Also handles 0x80000000 × 0 edge case correctly
    multiplier_coprocessor multiplier (
        .clk(clk),
        .reset(reset),
        .start(mult_start),
        .a(data1),              // rs1 register value
        .b(data2),              // rs2 register value (NOT immediate!)
        .funct3(instruction[14:12]),
        .result(mult_result),
        .done(mult_done),
        .busy(mult_busy)
    );
    
    // Multiplier Control FSM - FIXED: Proper 33-cycle stall timing
    multiplier_control mult_ctrl (
        .clk(clk),
        .reset(reset),
        .opcode(instruction[6:0]),
        .funct3(instruction[14:12]),
        .funct7(instruction[31:25]),
        .mult_done(mult_done),
        .mult_busy(mult_busy),
        .mult_start(mult_start),
        .stall_cpu(stall_cpu),
        .alu_control_out(mult_alu_control),
        .mult_write_pending(mult_write_pending)
    );
    
    // Data Memory
    data_memory dmem (
        .clk(clk),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .funct3(instruction[14:12]),
        .address(alu_result),
        .write_data(data2),
        .read_data(mem_read_data)
    );
    
    // Write-back Multiplexer
    write_back_mux wb_mux (
        .mem_to_reg(mem_to_reg),
        .jump(jump),
        .jalr(jalr),
        .lui(lui),
        .auipc(auipc),
        .alu_result(alu_result),
        .mem_data(mem_read_data),
        .pc_plus_4(pc_plus_4),
        .imm_out(imm_out),
        .pc_address(pc_address),
        .write_data(reg_write_data)
    );
    
    // Branch Comparison Logic (inline, no separate module)
    always_comb begin
        if (branch) begin
            case (instruction[14:12])  // funct3
                3'b000: branch_taken = (data1 == data2);                         // BEQ
                3'b001: branch_taken = (data1 != data2);                         // BNE
                3'b100: branch_taken = ($signed(data1) < $signed(data2));        // BLT
                3'b101: branch_taken = ($signed(data1) >= $signed(data2));       // BGE
                3'b110: branch_taken = (data1 < data2);                          // BLTU
                3'b111: branch_taken = (data1 >= data2);                         // BGEU
                default: branch_taken = 1'b0;
            endcase
        end
        else begin
            branch_taken = 1'b0;
        end
    end
    
    // Control Unit
    control control_unit (
        .opcode(instruction[6:0]),
        .funct3(instruction[14:12]),
        .funct7(instruction[31:25]),
        .mult_alu_control(mult_alu_control),
        .mult_instruction(mult_instruction),
        .reg_write(reg_write),
        .alu_src(alu_src),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .mem_to_reg(mem_to_reg),
        .branch(branch),
        .jump(jump),
        .jalr(jalr),
        .lui(lui),
        .auipc(auipc),
        .alu_control(alu_control)
    );
    
    // Multiplier instruction detection
    assign mult_instruction = (instruction[6:0] == 7'b0110011) && (instruction[25] == 1'b1);

endmodule