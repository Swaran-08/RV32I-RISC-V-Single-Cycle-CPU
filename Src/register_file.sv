module register_file (
    input  logic        clk,
    input  logic        reg_write,
    input  logic [4:0]  rs1,
    input  logic [4:0]  rs2,
    input  logic [4:0]  rd,
    input  logic [31:0] write_data,
    output logic [31:0] read_data1,
    output logic [31:0] read_data2
);

    logic [31:0] array [0:31];

    // x0 always reads as zero
    assign read_data1 = (rs1 == 5'd0) ? 32'd0 : array[rs1];
    assign read_data2 = (rs2 == 5'd0) ? 32'd0 : array[rs2];

    // Writes to x0 are ignored
    always_ff @(posedge clk) begin
        if (reg_write && (rd != 5'd0))
            array[rd] <= write_data;
    end

endmodule