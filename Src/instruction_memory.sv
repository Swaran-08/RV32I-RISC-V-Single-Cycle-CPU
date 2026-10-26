
module instr_mem (
    input  logic [31:0] addr,
    output logic [31:0] instr
);

    logic [31:0] mem [0:255];

    initial begin
    $readmemh("C:/Users/peesu/OneDrive/riscv/program.hex", mem);
    end

    assign instr = mem[addr[9:2]];

endmodule
