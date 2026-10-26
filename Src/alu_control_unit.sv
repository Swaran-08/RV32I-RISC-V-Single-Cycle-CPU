
module alu_control (
    input  logic [1:0] alu_op,
    input  logic [2:0] funct3,
    input  logic       funct7_bit5,
    input  logic       is_immediate,
    output logic [3:0] alu_control
);

    always_comb begin
        case (alu_op)

            2'b00: alu_control = 4'b0000; // ADD
            2'b01: alu_control = 4'b0001; // SUB

            2'b10: begin
                case (funct3)

                    3'b000: begin
                        if (!is_immediate && funct7_bit5)
                            alu_control = 4'b0001; // SUB
                        else
                            alu_control = 4'b0000; // ADD/ADDI
                    end

                    3'b001: alu_control = 4'b0111; // SLL
                    3'b010: alu_control = 4'b0101; // SLT
                    3'b011: alu_control = 4'b0110; // SLTU
                    3'b100: alu_control = 4'b0100; // XOR

                    3'b101: begin
                        if (funct7_bit5)
                            alu_control = 4'b1001; // SRA/SRAI
                        else
                            alu_control = 4'b1000; // SRL/SRLI
                    end

                    3'b110: alu_control = 4'b0011; // OR
                    3'b111: alu_control = 4'b0010; // AND

                    default: alu_control = 4'b0000;
                endcase
            end

            default: alu_control = 4'b0000;
        endcase
    end

endmodule
