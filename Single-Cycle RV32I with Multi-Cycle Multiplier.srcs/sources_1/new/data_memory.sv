module data_memory (
    input  logic        clk,
    input  logic        mem_read,
    input  logic        mem_write,
    input  logic [2:0]  funct3,
    input  logic [31:0] address,
    input  logic [31:0] write_data,
    output logic [31:0] read_data
);
    logic [7:0] mem [0:1023]; // 1KB byte-addressable memory
    
    initial begin
        for (int i = 0; i < 1024; i++) begin
            mem[i] = 8'b0;
        end
    end
    
    // Read logic (combinational)
    always_comb begin
        if (mem_read) begin
            case (funct3)
                3'b000: begin // LB - Load Byte (signed)
                    read_data = {{24{mem[address][7]}}, mem[address]};
                end
                3'b001: begin // LH - Load Halfword (signed)
                    read_data = {{16{mem[address+1][7]}}, mem[address+1], mem[address]};
                end
                3'b010: begin // LW - Load Word
                    read_data = {mem[address+3], mem[address+2], mem[address+1], mem[address]};
                end
                3'b100: begin // LBU - Load Byte Unsigned
                    read_data = {24'b0, mem[address]};
                end
                3'b101: begin // LHU - Load Halfword Unsigned
                    read_data = {16'b0, mem[address+1], mem[address]};
                end
                default: read_data = 32'b0;
            endcase
        end else begin
            read_data = 32'b0;
        end
    end
    
    // Write logic (sequential)
    always_ff @(posedge clk) begin
        if (mem_write) begin
            case (funct3)
                3'b000: begin // SB - Store Byte
                    mem[address] <= write_data[7:0];
                end
                3'b001: begin // SH - Store Halfword
                    mem[address]   <= write_data[7:0];
                    mem[address+1] <= write_data[15:8];
                end
                3'b010: begin // SW - Store Word
                    mem[address]   <= write_data[7:0];
                    mem[address+1] <= write_data[15:8];
                    mem[address+2] <= write_data[23:16];
                    mem[address+3] <= write_data[31:24];
                end
                default: ; // No operation
            endcase
        end
    end
endmodule

// Explanation:
// This SystemVerilog module implements a data memory for a RISC-V CPU. It supports reading and writing data of different sizes (byte, half-word, word)
// based on the funct3 field from the instruction. The memory is 1KB in size, organized as an array of 8-bit bytes.
// The module uses combinational logic to read data from memory when the mem_read signal is highest, applying sign extension or zero extension as needed.
// The write operation occurs on the rising edge of the clock when the mem_write signal is high, storing data into memory according to the specified size.
// The module handles the following funct3 codes:
// LB (000), LH (001), LW (010), LBU (100), LHU (101) for loads
// SB (000), SH (001), SW (010) for stores
// The read_data output provides the data read from memory, while write_data is the data to be written to memory.
