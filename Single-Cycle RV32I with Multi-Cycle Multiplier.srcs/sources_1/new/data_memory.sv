module data_memory (
    input  logic        clk,        // Source: System Clock
    input  logic        mem_read,   // Source: Control Unit
    input  logic        mem_write,  // Source: Control Unit
    input  logic [2:0]  funct3,     // Source: Instruction [14:12]
    input  logic [31:0] address,    // Source: ALU Result
    input  logic [31:0] write_data, // Source: Register File (rs2)
    output logic [31:0] read_data   // Dest: Write-Back Mux
);
    logic [7:0] mem [0:1023]; // 1KB byte-addressable memory
    
    initial begin
        for (int i = 0; i < 1024; i++) begin
            mem[i] = 8'b0;
        end
    end
    
    // Read logic
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
    
    // Write logic 
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
                default: ; 
            endcase
        end
    end
endmodule

// Explanation:
// This represents the Random Access Memory (RAM) for data (Heap/Stack).
//
// 1. **Byte Addressing**: The memory is an array of 8-bit bytes.
// 2. **Load Logic**: When reading a Word (`LW`), it concatenates 4 bytes: `mem[addr+3]...mem[addr]`.
//    It also handles `LB` (Load Byte) by sign-extending the 8-bit value to 32 bits, and `LBU` 
//    by zero-extending it.
// 3. **Store Logic**: When writing, it updates the specific bytes in the array based on the 
//    address and size (Byte, Half, Word).