module mem_to_reg_mux #(
    parameter DATA_WIDTH = 32
)(
    input  logic                    sel,
    input  logic [DATA_WIDTH-1:0]  alu_result,
    input  logic [DATA_WIDTH-1:0]  mem_data,
    output logic [DATA_WIDTH-1:0]  write_data
);
    assign write_data = sel ? mem_data : alu_result;
endmodule