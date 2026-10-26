
`timescale 1ns / 1ps

module tb_final_edge_regression;

    reg clk = 0;
    always #5 clk = ~clk;

    integer passed = 0;
    integer failed = 0;

    // ==================================================
    // ALU UNDER TEST
    // ==================================================

    reg [31:0] a, b;
    reg [3:0] alu_op;
    wire [31:0] alu_result;

    alu ALU_TEST (
        .a(a),
        .b(b),
        .alu_control(alu_op),
        .result(alu_result)
    );

    // ==================================================
    // ALU CONTROL UNDER TEST
    // ==================================================

    reg [1:0] control_alu_op;
    reg [2:0] funct3;
    reg funct7_bit5;
    reg is_immediate;

    wire [3:0] decoded_alu_op;

    alu_control CTRL_TEST (
        .alu_op(control_alu_op),
        .funct3(funct3),
        .funct7_bit5(funct7_bit5),
        .is_immediate(is_immediate),
        .alu_control(decoded_alu_op)
    );

    // ==================================================
    // DATA MEMORY UNDER TEST
    // ==================================================

    reg mem_read, mem_write;
    reg [2:0] load_type, store_type;
    reg [31:0] addr, write_data;
    wire [31:0] read_data;

    data_memory MEM_TEST (
        .clk(clk),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .load_type(load_type),
        .store_type(store_type),
        .addr(addr),
        .write_data(write_data),
        .read_data(read_data)
    );

    // ==================================================
    // TEST TASKS
    // ==================================================

    task check_alu;
        input [31:0] ta, tb;
        input [3:0] op;
        input [31:0] expected;
        input [8*48-1:0] name;
        begin
            a = ta;
            b = tb;
            alu_op = op;
            #1;

            if (alu_result === expected) begin
                $display("PASS: ALU %0s", name);
                passed = passed + 1;
            end
            else begin
                $display(
                    "FAIL: ALU %0s expected=%h actual=%h",
                    name, expected, alu_result
                );
                failed = failed + 1;
            end
        end
    endtask

    task check_control;
        input [1:0] op;
        input [2:0] f3;
        input f7bit5;
        input immediate;
        input [3:0] expected;
        input [8*48-1:0] name;
        begin
            control_alu_op = op;
            funct3 = f3;
            funct7_bit5 = f7bit5;
            is_immediate = immediate;
            #1;

            if (decoded_alu_op === expected) begin
                $display("PASS: CONTROL %0s", name);
                passed = passed + 1;
            end
            else begin
                $display(
                    "FAIL: CONTROL %0s expected=%b actual=%b",
                    name, expected, decoded_alu_op
                );
                failed = failed + 1;
            end
        end
    endtask

    task store_word;
        input [31:0] location;
        input [31:0] value;
        begin
            @(negedge clk);
            addr = location;
            write_data = value;
            store_type = 3'b010;
            mem_write = 1;

            @(posedge clk);
            #1;
            mem_write = 0;
        end
    endtask

    task check_load;
        input [31:0] location;
        input [2:0] kind;
        input [31:0] expected;
        input [8*48-1:0] name;
        begin
            @(negedge clk);
            addr = location;
            load_type = kind;
            mem_read = 1;
            #1;

            if (read_data === expected) begin
                $display("PASS: MEMORY %0s", name);
                passed = passed + 1;
            end
            else begin
                $display(
                    "FAIL: MEMORY %0s expected=%h actual=%h",
                    name, expected, read_data
                );
                failed = failed + 1;
            end

            mem_read = 0;
        end
    endtask

    // ==================================================
    // MAIN TEST SEQUENCE
    // ==================================================

    initial begin
        a = 0;
        b = 0;
        alu_op = 0;

        control_alu_op = 0;
        funct3 = 0;
        funct7_bit5 = 0;
        is_immediate = 0;

        mem_read = 0;
        mem_write = 0;
        load_type = 0;
        store_type = 0;
        addr = 0;
        write_data = 0;

        #2;

        $display("\n========================================");
        $display("        FINAL ALU EDGE TESTS");
        $display("========================================");

        // ----------------------------------------------
        // A. All ten ALU operations
        // ----------------------------------------------

        check_alu(10, 3,  4'b0000, 13, "ADD");
        check_alu(10, 3,  4'b0001, 7,  "SUB");
        check_alu('hF0, 'hCC, 4'b0010, 'hC0, "AND");
        check_alu('hF0, 'h0C, 4'b0011, 'hFC, "OR");
        check_alu('hAA, 'hFF, 4'b0100, 'h55, "XOR");

        check_alu('hFFFFFFFF, 1, 4'b0101, 1,
                  "SLT signed negative less than positive");
        check_alu('hFFFFFFFF, 1, 4'b0110, 0,
                  "SLTU unsigned comparison");

        check_alu(1, 4, 4'b0111, 16, "SLL");
        check_alu('h80, 2, 4'b1000, 'h20, "SRL");
        check_alu('h80000000, 1, 4'b1001,
                  'hC0000000, "SRA negative value");

        // ----------------------------------------------
        // B. Shift edge cases
        // ----------------------------------------------

        check_alu('h87654321, 0, 4'b0111,
                  'h87654321, "SLL shift by zero");

        check_alu(1, 31, 4'b0111,
                  'h80000000, "SLL shift by 31");

        check_alu('h80000000, 0, 4'b1000,
                  'h80000000, "SRL shift by zero");

        check_alu('h80000000, 31, 4'b1000,
                  1, "SRL shift by 31");

        check_alu('h80000000, 31, 4'b1001,
                  'hFFFFFFFF, "SRA shift by 31");

        check_alu('h7FFFFFFF, 31, 4'b1001,
                  0, "SRA positive value by 31");

        // ----------------------------------------------
        // C. ALU control: SLTIU, SRLI and SRAI
        // ----------------------------------------------

        check_control(2'b10, 3'b011, 0, 1,
                      4'b0110, "SLTIU decodes to SLTU");

        check_control(2'b10, 3'b101, 0, 1,
                      4'b1000, "SRLI decodes to SRL");

        check_control(2'b10, 3'b101, 1, 1,
                      4'b1001, "SRAI decodes to SRA");

        // Verify the corresponding ALU operations.
        check_alu(1, 2, 4'b0110, 1, "SLTIU result");
        check_alu('h80000000, 1, 4'b1000,
                  'h40000000, "SRLI result");
        check_alu('h80000000, 1, 4'b1001,
                  'hC0000000, "SRAI result");

        // ----------------------------------------------
        // D. Initialize memory with known byte pattern
        // Little-endian bytes: 01, 7F, FF, 80
        // ----------------------------------------------

        $display("\n===== MEMORY LOAD EDGE TESTS =====");

        store_word(0, 'h80FF7F01);

        // LBU: all four byte offsets
        check_load(0, 3'b100, 'h00000001, "LBU offset 0");
        check_load(1, 3'b100, 'h0000007F, "LBU offset 1");
        check_load(2, 3'b100, 'h000000FF, "LBU offset 2");
        check_load(3, 3'b100, 'h00000080, "LBU offset 3");

        // LHU: both halfword positions in the word
        check_load(0, 3'b101, 'h00007F01, "LHU offset 0");
        check_load(2, 3'b101, 'h000080FF, "LHU offset 2");

        // Additional signed-load checks
        check_load(3, 3'b000, 'hFFFFFF80, "LB signed offset 3");
        check_load(2, 3'b001, 'hFFFF80FF, "LH signed offset 2");

        // ----------------------------------------------
        // E. Summary
        // ----------------------------------------------

        $display("\n========================================");
        $display("        FINAL REGRESSION SUMMARY");
        $display("========================================");
        $display("Tests passed : %0d", passed);
        $display("Tests failed : %0d", failed);
        $display("Total tests  : %0d", passed + failed);

        if (failed == 0)
            $display("RESULT: ALL MODULE EDGE TESTS PASSED");
        else
            $display("RESULT: FAILURES FOUND - CHECK LOG");

        $display("========================================\n");

        $finish;
    end

    initial begin
        #5000;
        $display("ERROR: Testbench timeout");
        $finish;
    end

endmodule
