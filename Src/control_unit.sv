module control_unit (
    input  logic [6:0] opcode,
    input  logic [2:0] funct3,

    output logic       reg_write,
    output logic       mem_read,
    output logic       mem_write,
    output logic       mem_to_reg,
    output logic       alu_src,
    output logic [1:0] alu_op,
    output logic       branch,
    output logic       jump,
    output logic       lui,
    output logic       auipc,
    output logic [2:0] load_type,
    output logic [2:0] store_type
);

    always_comb begin

        // Default values
        reg_write = 1'b0;
        mem_read  = 1'b0;
        mem_write = 1'b0;
        mem_to_reg = 1'b0;
        alu_src   = 1'b0;
        alu_op    = 2'b00;
        branch    = 1'b0;
        jump      = 1'b0;
        lui       = 1'b0;
        auipc     = 1'b0;
        load_type = 3'b010;
        store_type = 3'b010;

        case (opcode)

            // R-type: ADD, SUB, AND, OR, XOR, SLT, SLTU,
            //         SLL, SRL, SRA
            7'b0110011: begin
                reg_write = 1'b1;
                alu_src   = 1'b0;
                alu_op    = 2'b10;
            end

            // I-type arithmetic: ADDI, ANDI, ORI, XORI,
            //                    SLTI, SLTIU, SLLI, SRLI, SRAI
            7'b0010011: begin
                reg_write = 1'b1;
                alu_src   = 1'b1;
                alu_op    = 2'b10;
            end

            // Loads: LB, LH, LW, LBU, LHU
            7'b0000011: begin
                alu_src    = 1'b1;
                alu_op     = 2'b00;
                mem_read   = 1'b1;
                mem_to_reg = 1'b1;
                reg_write  = 1'b1;

                case (funct3)
                    3'b000: load_type = 3'b000; // LB
                    3'b001: load_type = 3'b001; // LH
                    3'b010: load_type = 3'b010; // LW
                    3'b100: load_type = 3'b100; // LBU
                    3'b101: load_type = 3'b101; // LHU

                    default: begin
                        mem_read   = 1'b0;
                        mem_to_reg = 1'b0;
                        reg_write  = 1'b0;
                    end
                endcase
            end

            // Stores: SB, SH, SW
            7'b0100011: begin
                alu_src  = 1'b1;
                alu_op   = 2'b00;
                mem_write = 1'b1;

                case (funct3)
                    3'b000: store_type = 3'b000; // SB
                    3'b001: store_type = 3'b001; // SH
                    3'b010: store_type = 3'b010; // SW

                    default: mem_write = 1'b0;
                endcase
            end

            // Branches: BEQ, BNE, BLT, BGE, BLTU, BGEU
            7'b1100011: begin
                branch = 1'b1;
                alu_op = 2'b01;
            end

            // JAL
            7'b1101111: begin
                reg_write = 1'b1;
                jump      = 1'b1;
                alu_src   = 1'b0;
            end

            // JALR
            7'b1100111: begin
                reg_write = 1'b1;
                jump      = 1'b1;
                alu_src   = 1'b1;
                alu_op    = 2'b00;
            end

            // LUI
            7'b0110111: begin
                reg_write = 1'b1;
                lui       = 1'b1;
                alu_src   = 1'b1;
            end

            // AUIPC
            7'b0010111: begin
                reg_write = 1'b1;
                auipc     = 1'b1;
                alu_src   = 1'b1;
                alu_op    = 2'b00;
            end

            // Unsupported instructions retain default controls.
            default: begin
            end

        endcase
    end

endmodule