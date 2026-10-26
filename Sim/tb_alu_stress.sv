
`timescale 1ns / 1ps

module tb_alu_stress;

    logic [31:0] a, b;
    logic [3:0] alu_op_code;
    logic [31:0] result;

    logic [1:0] alu_op;
    logic [2:0] funct3;
    logic funct7_bit5, is_immediate;
    logic [3:0] alu_control_out;

    integer errors = 0;

    alu ALU (
        .a(a),
        .b(b),
        .alu_control(alu_op_code),
        .result(result)
    );

    alu_control ALU_CTRL (
        .alu_op(alu_op),
        .funct3(funct3),
        .funct7_bit5(funct7_bit5),
        .is_immediate(is_immediate),
        .alu_control(alu_control_out)
    );

    task automatic check_alu(
        input logic [31:0] va,
        input logic [31:0] vb,
        input logic [3:0] op,
        input logic [31:0] expected,
        input string name
    );
        begin
            a = va;
            b = vb;
            alu_op_code = op;
            #1;

            if (result === expected)
                $display("PASS: %s = %08h", name, result);
            else begin
                $display("FAIL: %s got %08h expected %08h",
                         name, result, expected);
                errors = errors + 1;
            end
        end
    endtask

    task automatic check_control(
        input logic [1:0] op,
        input logic [2:0] f3,
        input logic f7bit5,
        input logic imm,
        input logic [3:0] expected,
        input string name
    );
        begin
            alu_op = op;
            funct3 = f3;
            funct7_bit5 = f7bit5;
            is_immediate = imm;
            #1;

            if (alu_control_out === expected)
                $display("PASS: %s = %04b",
                         name, alu_control_out);
            else begin
                $display("FAIL: %s got %04b expected %04b",
                         name, alu_control_out, expected);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        a = 0;
        b = 0;
        alu_op_code = 0;
        alu_op = 0;
        funct3 = 0;
        funct7_bit5 = 0;
        is_immediate = 0;

        #2;

        // =========================================
        // GROUP 1: ALU ARITHMETIC / LOGIC BOUNDARIES
        // =========================================

        $display("\n=== GROUP 1: ALU BOUNDARIES ===");

        check_alu(32'h7FFFFFFF, 32'd1, 4'b0000,
                  32'h80000000, "ADD signed overflow");

        check_alu(32'hFFFFFFFF, 32'd1, 4'b0000,
                  32'h00000000, "ADD wraparound");

        check_alu(32'd0, 32'd1, 4'b0001,
                  32'hFFFFFFFF, "SUB underflow");

        check_alu(32'h80000000, 32'd1, 4'b0001,
                  32'h7FFFFFFF, "SUB boundary");

        check_alu(32'hF0F0AA55, 32'h0FF00FF0, 4'b0010,
                  32'h00F00A50, "AND");

        check_alu(32'hF0F0AA55, 32'h0FF00FF0, 4'b0011,
                  32'hFFF0AFF5, "OR");

        check_alu(32'hAAAAAAAA, 32'h55555555, 4'b0100,
                  32'hFFFFFFFF, "XOR");

        check_alu(32'hFFFFFFFF, 32'd1, 4'b0101,
                  32'd1, "SLT signed");

        check_alu(32'hFFFFFFFF, 32'd1, 4'b0110,
                  32'd0, "SLTU unsigned");

        // =========================================
        // GROUP 2: SHIFT BOUNDARIES
        // =========================================

        $display("\n=== GROUP 2: SHIFT BOUNDARIES ===");

        check_alu(32'd1, 32'd0, 4'b0111,
                  32'd1, "SLL shift 0");

        check_alu(32'd1, 32'd31, 4'b0111,
                  32'h80000000, "SLL shift 31");

        check_alu(32'h80000000, 32'd31, 4'b1000,
                  32'd1, "SRL shift 31");

        check_alu(32'h80000000, 32'd31, 4'b1001,
                  32'hFFFFFFFF, "SRA shift 31");

        check_alu(32'hFFFFFFFF, 32'd0, 4'b1001,
                  32'hFFFFFFFF, "SRA shift 0");

        // Only the low five bits of b determine the shift.
        check_alu(32'd1, 32'd32, 4'b0111,
                  32'd1, "Shift amount uses low five bits");

        // =========================================
        // GROUP 3: ALU CONTROL DECODING
        // =========================================

        $display("\n=== GROUP 3: ALU CONTROL ===");

        check_control(2'b00, 3'b000, 1'b0, 1'b0,
                      4'b0000, "Address ADD");

        check_control(2'b01, 3'b000, 1'b0, 1'b0,
                      4'b0001, "Branch SUB");

        check_control(2'b10, 3'b000, 1'b0, 1'b0,
                      4'b0000, "R-type ADD");

        check_control(2'b10, 3'b000, 1'b1, 1'b0,
                      4'b0001, "R-type SUB");

        check_control(2'b10, 3'b000, 1'b1, 1'b1,
                      4'b0000, "ADDI with bit 30 set");

        check_control(2'b10, 3'b001, 1'b0, 1'b0,
                      4'b0111, "SLL");

        check_control(2'b10, 3'b010, 1'b0, 1'b0,
                      4'b0101, "SLT");

        check_control(2'b10, 3'b011, 1'b0, 1'b0,
                      4'b0110, "SLTU");

        check_control(2'b10, 3'b100, 1'b0, 1'b0,
                      4'b0100, "XOR");

        check_control(2'b10, 3'b101, 1'b0, 1'b0,
                      4'b1000, "SRL");

        check_control(2'b10, 3'b101, 1'b1, 1'b0,
                      4'b1001, "SRA");

        check_control(2'b10, 3'b101, 1'b1, 1'b1,
                      4'b1001, "SRAI");

        check_control(2'b10, 3'b110, 1'b0, 1'b0,
                      4'b0011, "OR");

        check_control(2'b10, 3'b111, 1'b0, 1'b0,
                      4'b0010, "AND");

        $display("\n=== FINAL RESULT ===");

        if (errors == 0)
            $display("ALL ALU TESTS PASSED");
        else
            $display("ALU TEST FAILED: %0d error(s)", errors);

        $finish;
    end

endmodule
