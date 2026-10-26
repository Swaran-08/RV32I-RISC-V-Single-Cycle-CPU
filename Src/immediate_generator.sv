
module immediate_generator (
    input  logic [31:0] instr,
    output logic [31:0] imm_out
);

    always_comb begin
        case (instr[6:0])

            // I-type: Arithmetic and Load
            7'b0010011,
            7'b0000011,
            7'b1100111: begin
                imm_out = {{20{instr[31]}}, instr[31:20]};
            end 

            // S-type: Store
            7'b0100011: begin
                imm_out = {{20{instr[31]}},
                           instr[31:25], instr[11:7]};
            end

            // B-type: Branch
            7'b1100011: begin
                imm_out = {{19{instr[31]}},
                           instr[31],
                           instr[7],
                           instr[30:25],
                           instr[11:8],
                           1'b0};
            end

            // U-type: LUI and AUIPC
            7'b0110111,
            7'b0010111: begin
                imm_out = {instr[31:12], 12'b0};
            end

            // J-type: JAL
            7'b1101111: begin
                imm_out = {{11{instr[31]}},
                           instr[31],
                           instr[19:12],
                           instr[20],
                           instr[30:21],
                           1'b0};
            end

            // Unsupported instruction
            default: begin
                imm_out = 32'b0;
            end

        endcase
    end

endmodule
