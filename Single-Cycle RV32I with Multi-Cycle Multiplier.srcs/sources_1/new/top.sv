module top_with_multiplier #(
    parameter DATA_WIDTH = 32,
    parameter ADDRESS_WIDTH = 32
)(
    input  logic clk,
    input  logic reset
);

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
    
    logic [31:0] mult_result;
    logic        mult_start, mult_done, mult_busy;
    logic        stall_cpu;
    logic [3:0]  mult_alu_control;
    logic        mult_instruction;
    logic        mult_write_pending;  // NEW: Special write enable for multiplier
    
    assign pc_plus_4 = pc_address + 4;
    assign branch_target = pc_address + imm_out;
    assign jump_target = jalr ? ((data1 + imm_out) & ~32'b1) : (pc_address + imm_out);
    
    assign pc_next = stall_cpu ? pc_address : 
                    (branch_taken ? branch_target : 
                    (jump || jalr ? jump_target : pc_plus_4));
    
    program_counter pc (
        .clk(clk),
        .reset(reset),
        .pc_next(pc_next),
        .pc_address(pc_address)
    );
    
    instruction_memory imem (
        .address(pc_address[2:0]),
        .instruction(instruction)
    );
    
    // FIXED: Use special multiplier write enable
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
    
    imm_gen imm_gen (
        .instruction(instruction),
        .imm_out(imm_out)
    );
    
    mux_2to1 alu_a_mux (
        .sel(auipc),
        .in0(data1),
        .in1(pc_address),
        .out(alu_operand_a)
    );
    
    mux_2to1 alu_src_mux (
        .sel(alu_src),
        .in0(data2),
        .in1(imm_out),
        .out(alu_operand2)
    );
    
    alu_with_multiplier alu (
        .a(alu_operand_a),
        .b(alu_operand2),
        .alu_control(alu_control),
        .mult_result(mult_result),
        .mult_done(mult_done),
        .result(alu_result),
        .zero(zero)
    );
    
    multiplier_coprocessor multiplier (
        .clk(clk),
        .reset(reset),
        .start(mult_start),
        .a(data1),
        .b(alu_operand2),
        .funct3(instruction[14:12]),
        .result(mult_result),
        .done(mult_done),
        .busy(mult_busy)
    );
    
    // FIXED: multiplier_control with proper write timing
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
    
    data_memory dmem (
        .clk(clk),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .funct3(instruction[14:12]),
        .address(alu_result),
        .write_data(data2),
        .read_data(mem_read_data)
    );
    
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
    
    // Branch comparison logic (inline, no separate module)
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
    
    control_enhanced control_unit (
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
    
    assign mult_instruction = (instruction[6:0] == 7'b0110011) && (instruction[31:25][0] == 1'b1);

endmodule