module register_file #(
    parameter DATA_WIDTH = 32,
    parameter NUM_REGISTERS = 32,
    parameter ADDR_WIDTH = 5
)(
    input  logic                      clk,          // Source: System Clock
    input  logic                      reset,        // Source: System Reset
    input  logic                      write_enable, // Source: Control Unit (gated by stall logic)
    input  logic [ADDR_WIDTH-1:0]     rs1,          // Source: Instruction [19:15]
    input  logic [ADDR_WIDTH-1:0]     rs2,          // Source: Instruction [24:20]
    input  logic [ADDR_WIDTH-1:0]     rd,           // Source: Instruction [11:7]
    input  logic [DATA_WIDTH-1:0]     write_data,   // Source: Write-Back Mux
    output logic [DATA_WIDTH-1:0]     out_rs1,      // Dest: ALU (Operand A) & Multiplier
    output logic [DATA_WIDTH-1:0]     out_rs2       // Dest: ALU (Operand B), Multiplier & Data Memory
);
    logic [DATA_WIDTH-1:0] registers [0:NUM_REGISTERS-1];
    
    initial begin
        for (int i = 0; i < NUM_REGISTERS; i++) begin
            registers[i] = '0;
        end
    end
    
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            for (int i = 0; i < NUM_REGISTERS; i++) begin
                registers[i] <= '0;
            end
        end 
        else if (write_enable && rd != 5'b00000) begin
            registers[rd] <= write_data;
        end
    end
    
    always_comb begin
        out_rs1 = (rs1 == 5'b00000) ? '0 : registers[rs1];
        out_rs2 = (rs2 == 5'b00000) ? '0 : registers[rs2];
    end
endmodule

// Explanation:
// This is the processor's internal storage, implementing the 32 General Purpose Registers (x0-x31).
//
// 1. **Three-Port Architecture**: It allows simultaneous reading of two registers (`rs1`, `rs2`) 
//    and writing of one register (`rd`) in a single clock cycle.
// 2. **x0 Hardwiring**: In RISC-V, register `x0` is hardwired to zero. The logic `rd != 5'b00000` 
//    prevents writing to x0, and the read logic explicitly returns 0 if x0 is requested.
// 3. **Write Logic & Stalls**: The `write_enable` signal is critical. In the Top module, this signal 
//    is logic: `(reg_write && !stall_cpu) || mult_write_pending`.
//    - Normally, we write if the instruction says so (`reg_write`).
//    - BUT, if the CPU is stalled (multiplier running), we forbid writing to prevent corruption.
//    - UNLESS, the multiplier just finished (`mult_write_pending`), in which case we allow the write.