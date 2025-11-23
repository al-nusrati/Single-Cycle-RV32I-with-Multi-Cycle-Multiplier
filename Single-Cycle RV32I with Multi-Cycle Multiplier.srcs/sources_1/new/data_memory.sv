module data_memory (
    input  logic clk,
    input  logic mem_read,
    input  logic mem_write,
    input  logic [2:0]  funct3,
    input  logic [31:0] address,
    input  logic [31:0] write_data,
    output logic [31:0] read_data
);
    logic [7:0] mem [0:1023];
    
    initial begin
        for (int i = 0; i < 1024; i++) begin
            mem[i] = 8'b0;
        end
    end
    
    always_comb begin
        if (mem_read) begin
            case (funct3)
                3'b000: read_data = {{24{mem[address][7]}}, mem[address]};
                3'b001: read_data = {{16{mem[address+1][7]}}, mem[address+1], mem[address]};
                3'b010: read_data = {mem[address+3], mem[address+2], mem[address+1], mem[address]};
                3'b100: read_data = {24'b0, mem[address]};
                3'b101: read_data = {16'b0, mem[address+1], mem[address]};
                default: read_data = 32'b0;
            endcase
        end
        else begin
            read_data = 32'b0;
        end
    end
    
    always_ff @(posedge clk) begin
        if (mem_write) begin
            case (funct3)
                3'b000: mem[address] <= write_data[7:0];
                3'b001: begin
                    mem[address]   <= write_data[7:0];
                    mem[address+1] <= write_data[15:8];
                end
                3'b010: begin
                    mem[address]   <= write_data[7:0];
                    mem[address+1] <= write_data[15:8];
                    mem[address+2] <= write_data[23:16];
                    mem[address+3] <= write_data[31:24];
                end
                default: ;
            endcase
        end
    end
endmodule