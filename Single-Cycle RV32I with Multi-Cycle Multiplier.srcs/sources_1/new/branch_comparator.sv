module branch_comparator (
    input  logic [31:0] data1,
    input  logic [31:0] data2,
    input  logic [2:0]  funct3,
    input  logic        branch,
    output logic        branch_taken
);
    always_comb begin
        if (branch) begin
            case (funct3)
                3'b000: branch_taken = (data1 == data2);
                3'b001: branch_taken = (data1 != data2);
                3'b100: branch_taken = ($signed(data1) < $signed(data2));
                3'b101: branch_taken = ($signed(data1) >= $signed(data2));
                3'b110: branch_taken = (data1 < data2);
                3'b111: branch_taken = (data1 >= data2);
                default: branch_taken = 1'b0;
            endcase
        end
        else begin
            branch_taken = 1'b0;
        end
    end
endmodule
