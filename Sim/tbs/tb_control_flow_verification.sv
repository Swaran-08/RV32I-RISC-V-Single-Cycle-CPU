
`timescale 1ns / 1ps

module tb_control_flow_verification;

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

        // Initialize registers and memory for deterministic testing.
        for (i = 0; i < 32; i = i + 1)
            DUT.RF.array[i] = 32'b0;

        for (i = 0; i < 256; i = i + 1)
            DUT.DMEM.mem[i] = 32'b0;

        repeat (2) @(posedge clk);
        @(negedge clk);
        reset = 0;

        // Execute program and allow the final loop to settle.
        repeat (40) @(posedge clk);
        #1;

        $display("\n=== GROUP 1: BRANCHES ===");

        check_reg(10, 32'd10, "BEQ taken");
        check_reg(11, 32'd11, "BNE not taken");
        check_reg(12, 32'd12, "BLT signed taken");
        check_reg(13, 32'd13, "BLTU unsigned not taken");
        check_reg(14, 32'd0,  "Backward BNE loop completed");

        $display("\n=== GROUP 2: JUMPS ===");

        check_reg(5,  32'h00000048, "JAL link address");
        check_reg(7,  32'h00000058, "JALR link address");
        check_reg(8,  32'h0000005C, "JALR target base");

        check_reg(15, 32'd0, "JAL skipped instruction");
        check_reg(16, 32'd16, "JAL target executed");
        check_reg(17, 32'd0, "JALR skipped instruction");
        check_reg(18, 32'd18, "JALR target executed");

        $display("\n=== GROUP 3: WRITE SAFETY ===");

        check_reg(19, 32'd0, "Invalid load does not write rd");
        check_reg(20, 32'd0, "Unsupported opcode does not write rd");

        if (DUT.DMEM.mem[0] === 32'd0)
            $display("PASS: Invalid store preserves memory");
        else begin
            $display("FAIL: mem[0] changed to %08h",
                     DUT.DMEM.mem[0]);
            errors = errors + 1;
        end

        if (pc_out === 32'h0000006C)
            $display("PASS: Final PC self-loop = 0000006C");
        else begin
            $display("FAIL: Final PC = %08h", pc_out);
            errors = errors + 1;
        end

        $display("\n=== FINAL RESULT ===");

        if (errors == 0)
            $display("ALL THREE GROUPS PASSED");
        else
            $display("TEST FAILED: %0d error(s)", errors);

        $finish;
    end

endmodule
