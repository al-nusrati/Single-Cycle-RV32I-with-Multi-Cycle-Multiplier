module register_file #(
    parameter DATA_WIDTH = 32,
    parameter NUM_REGISTERS = 32,
    parameter ADDR_WIDTH = 5
)(
    input  logic                      clk,
    input  logic                      reset,
    input  logic                      write_enable,
    input  logic [ADDR_WIDTH-1:0]     rs1,
    input  logic [ADDR_WIDTH-1:0]     rs2,
    input  logic [ADDR_WIDTH-1:0]     rd,
    input  logic [DATA_WIDTH-1:0]     write_data,
    output logic [DATA_WIDTH-1:0]     out_rs1,
    output logic [DATA_WIDTH-1:0]     out_rs2
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