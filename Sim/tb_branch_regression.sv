
`timescale 1ns / 1ps

module tb_branch_regression;

    reg clk = 0;
    reg reset = 1;
    wire [31:0] pc_out;

    integer passed = 0;
    integer failed = 0;

    single_cycle_top DUT (
        .clk(clk),
        .reset(reset),
        .pc_out(pc_out)
    );

    always #5 clk = ~clk;

    task check_branch;
        input integer reg_num;
        input [31:0] expected;
        input [8*48-1:0] test_name;
        begin
            if (DUT.RF.array[reg_num] === expected) begin
                $display("PASS: %0s", test_name);
                passed = passed + 1;
            end
            else begin
                $display(
                    "FAIL: %0s expected=%h actual=%h",
                    test_name,
                    expected,
                    DUT.RF.array[reg_num]
                );
                failed = failed + 1;
            end
        end
    endtask

    initial begin
        repeat (2) @(posedge clk);
        @(negedge clk);
        reset = 0;

        // 41 instructions, followed by a self-loop.
        repeat (45) @(posedge clk);
        #1;

        $display("\n========================================");
        $display("      BRANCH REGRESSION RESULTS");
        $display("========================================");

        // BEQ
        check_branch(10, 0, "BEQ taken");
        check_branch(11, 1, "BEQ not taken");

        // BNE
        check_branch(12, 0, "BNE taken");
        check_branch(13, 1, "BNE not taken");

        // BLT: signed comparison
        check_branch(14, 0, "BLT taken");
        check_branch(15, 1, "BLT not taken");

        // BGE: signed comparison
        check_branch(16, 0, "BGE taken");
        check_branch(17, 1, "BGE not taken");

        // BLTU: unsigned comparison
        check_branch(18, 0, "BLTU taken");
        check_branch(19, 1, "BLTU not taken");

        // BGEU: unsigned comparison
        check_branch(20, 0, "BGEU taken");
        check_branch(21, 1, "BGEU not taken");

        $display("\n========================================");
        $display("Tests passed : %0d", passed);
        $display("Tests failed : %0d", failed);
        $display("Total tests  : %0d", passed + failed);

        if (failed == 0)
            $display("RESULT: ALL BRANCH TESTS PASSED");
        else
            $display("RESULT: BRANCH TESTS FAILED");

        $display("========================================\n");
        $finish;
    end

    initial begin
        #2000;
        $display("ERROR: Branch testbench timeout");
        $finish;
    end

endmodule
