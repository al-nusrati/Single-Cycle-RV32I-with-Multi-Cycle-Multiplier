module program_counter (
    input  logic clk,
    input  logic reset,
    input  logic [31:0] pc_next,        // from top module
    output logic [31:0] pc_address     // to top module
);
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            pc_address <= 32'h0;
        end
        else begin
            pc_address <= pc_next;
        end
    end
endmodule