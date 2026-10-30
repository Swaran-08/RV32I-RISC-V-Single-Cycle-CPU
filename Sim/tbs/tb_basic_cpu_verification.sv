
`timescale 1ns / 1ps

module tb_basic_cpu_verification;

    logic clk, reset;
    logic [31:0] pc_out;
    integer errors, i;

    single_cycle_top DUT (
        .clk(clk),
        .reset(reset),
        .pc_out(pc_out)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    task automatic check_reg(
        input integer n,
        input logic [31:0] expected,
        input string name
    );
        begin
            if (DUT.RF.array[n] === expected)
                $display("PASS: %s = %08h", name, expected);
            else begin
                $display("FAIL: %s got %08h expected %08h",
                         name, DUT.RF.array[n], expected);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        errors = 0;
        reset = 1;

        // Initialize registers and data memory for simulation.
        for (i = 0; i < 32; i = i + 1)
            DUT.RF.array[i] = 32'b0;

        for (i = 0; i < 256; i = i + 1)
            DUT.DMEM.mem[i] = 32'b0;

        repeat (2) @(posedge clk);
        @(negedge clk);
        reset = 0;

        // Run through AUIPC, immediate, x0, NOP,
        // unsupported instruction, store, and loop.
        repeat (14) @(posedge clk);
        #1;

        $display("\n=== TEST 1: AUIPC / IMMEDIATES ===");

        check_reg(1, 32'h00000005, "ADDI baseline");
        check_reg(2, 32'h00000004, "AUIPC at PC 4");
        check_reg(3, 32'h00001008, "AUIPC at PC 8");
        check_reg(4, 32'hFFFFFFFF, "ADDI negative immediate");

        $display("\n=== TEST 2: x0 / NOP ===");

        check_reg(0, 32'h00000000, "x0 remains zero");

        // Explicitly verify x0's read path.
        if (DUT.rs1_data === 32'b0)
            $display("PASS: x0 read path returns zero");
        else begin
            $display("FAIL: x0 read path is nonzero");
            errors = errors + 1;
        end

        $display("\n=== TEST 3: UNSUPPORTED OPCODE ===");

        // The unsupported instruction is at address 0x18.
        // It must not cause register or memory writes.
        check_reg(1, 32'h00000005,
                  "Unsupported instruction preserves x1");

        if (DUT.DMEM.mem[0] === 32'h00000005)
            $display("PASS: SW executed; memory = 00000005");
        else begin
            $display("FAIL: memory = %08h, expected 00000005",
                     DUT.DMEM.mem[0]);
            errors = errors + 1;
        end

        // The program ends in a JAL x0,0 self-loop at 0x20.
        if (pc_out === 32'h00000020)
            $display("PASS: Final PC = 00000020");
        else begin
            $display("FAIL: Final PC = %08h", pc_out);
            errors = errors + 1;
        end

        $display("\n=== FINAL RESULT ===");

        if (errors == 0)
            $display("ALL CHECKED RESULTS PASSED");
        else
            $display("TEST FAILED: %0d error(s)", errors);

        $finish;
    end

endmodule
