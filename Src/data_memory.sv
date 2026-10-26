module data_memory (
    input  logic        clk,
    input  logic        mem_read,
    input  logic        mem_write,
    input  logic [2:0]  load_type,
    input  logic [2:0]  store_type,
    input  logic [31:0] addr,
    input  logic [31:0] write_data,
    output logic [31:0] read_data
);

    logic [31:0] mem [0:255];

    logic [31:0] selected_word;
    logic [7:0]  selected_byte;
    logic [15:0] selected_half;

    integer i;

    // Initialize memory for simulation.
    initial begin
        for (i = 0; i < 256; i = i + 1)
            mem[i] = 32'b0;
    end

    // Select the word containing the requested byte.
    always_comb begin
        selected_word = mem[addr[9:2]];

        case (addr[1:0])
            2'b00: selected_byte = selected_word[7:0];
            2'b01: selected_byte = selected_word[15:8];
            2'b10: selected_byte = selected_word[23:16];
            2'b11: selected_byte = selected_word[31:24];
        endcase

        if (addr[1] == 1'b0)
            selected_half = selected_word[15:0];
        else
            selected_half = selected_word[31:16];

        read_data = 32'b0;

        if (mem_read) begin
            case (load_type)
                3'b000: read_data = {{24{selected_byte[7]}},
                                      selected_byte}; // LB

                3'b001: read_data = {{16{selected_half[15]}},
                                      selected_half}; // LH

                3'b010: read_data = selected_word; // LW

                3'b100: read_data = {24'b0,
                                      selected_byte}; // LBU

                3'b101: read_data = {16'b0,
                                      selected_half}; // LHU

                default: read_data = 32'b0;
            endcase
        end
    end

    // Write only the selected byte, halfword, or word.
    always_ff @(posedge clk) begin
        if (mem_write) begin
            case (store_type)

                3'b000: begin // SB
                    case (addr[1:0])
                        2'b00: mem[addr[9:2]][7:0]
                                   <= write_data[7:0];
                        2'b01: mem[addr[9:2]][15:8]
                                   <= write_data[7:0];
                        2'b10: mem[addr[9:2]][23:16]
                                   <= write_data[7:0];
                        2'b11: mem[addr[9:2]][31:24]
                                   <= write_data[7:0];
                    endcase
                end

                3'b001: begin // SH
                    if (addr[1] == 1'b0)
                        mem[addr[9:2]][15:0]
                            <= write_data[15:0];
                    else
                        mem[addr[9:2]][31:16]
                            <= write_data[15:0];
                end

                3'b010: begin // SW
                    mem[addr[9:2]] <= write_data;
                end

                default: begin
                    // Unsupported store type: no write.
                end

            endcase
        end
    end

endmodule