
`timescale 1ns / 1ps

module tb_cpu_integration_verification;

    reg clk = 0;
    reg reset = 1;
    wire [31:0] pc_out;

    integer errors = 0;

    single_cycle_top DUT (
        .clk(clk),
        .reset(reset),
        .pc_out(pc_out)
    );

    always #5 clk = ~clk;

    // Immediate generator test
    reg [31:0] imm_instr;
    wire [31:0] imm_out;

    immediate_generator IG_TEST (
        .instr(imm_instr),
        .imm_out(imm_out)
    );

    // Register-file x0 test
    reg rf_we = 0;
    reg [4:0] rf_rs1 = 0, rf_rs2 = 0, rf_rd = 0;
    reg [31:0] rf_wdata = 0;
    wire [31:0] rf_rdata1, rf_rdata2;

    register_file RF_TEST (
        .clk(clk),
        .reg_write(rf_we),
        .rs1(rf_rs1),
        .rs2(rf_rs2),
        .rd(rf_rd),
        .write_data(rf_wdata),
        .read_data1(rf_rdata1),
        .read_data2(rf_rdata2)
    );

    task check_reg;
        input integer n;
        input [31:0] expected;
        input [8*40-1:0] name;
        begin
            if (DUT.RF.array[n] === expected)
                $display("PASS: %0s", name);
            else begin
                $display("FAIL: %0s expected=%h actual=%h",
                         name, expected, DUT.RF.array[n]);
                errors = errors + 1;
            end
        end
    endtask

    task check_mem;
        input integer n;
        input [31:0] expected;
        input [8*40-1:0] name;
        begin
            if (DUT.DMEM.mem[n] === expected)
                $display("PASS: %0s", name);
            else begin
                $display("FAIL: %0s expected=%h actual=%h",
                         name, expected, DUT.DMEM.mem[n]);
                errors = errors + 1;
            end
        end
    endtask

    task check_imm;
        input [31:0] instr;
        input [31:0] expected;
        input [8*40-1:0] name;
        begin
            imm_instr = instr;
            #1;
            if (imm_out === expected)
                $display("PASS: IMM %0s", name);
            else begin
                $display("FAIL: IMM %0s expected=%h actual=%h",
                         name, expected, imm_out);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        imm_instr = 32'b0;

        repeat (2) @(posedge clk);
        @(negedge clk);
        reset = 0;

        // Run CPU program through terminal loop
        repeat (55) @(posedge clk);
        #1;

        $display("\n===== CPU INTEGRATION REGRESSION =====");

        check_reg(1,  32'd5,         "ADDI x1");
        check_reg(2,  32'd5,         "ADDI x2");
        check_reg(3,  32'd10,        "ADDI x3");

        check_reg(4,  32'd5,         "LB offset 1");
        check_reg(5,  32'd5,         "LH offset 2");
        check_reg(6,  32'h0005050a,  "LW after SB and SH");
        check_reg(7,  32'd0,         "LBU offset 3");
        check_reg(8,  32'd5,         "LHU offset 2");

        check_reg(9,  32'd1,         "BEQ taken");
        check_reg(10, 32'd2,         "BNE not taken");
        check_reg(11, 32'd3,         "BNE taken");
        check_reg(12, 32'hffffffff, "Negative immediate");
        check_reg(13, 32'd4,         "BLT signed taken");
        check_reg(14, 32'd5,         "BGE signed taken");
        check_reg(15, 32'd6,         "BLTU unsigned not taken");
        check_reg(16, 32'd7,         "Following BLTU");
        check_reg(17, 32'd8,         "BGEU unsigned taken");

        check_reg(18, 32'h00000088,  "JAL link address");
        check_reg(19, 32'd9,         "JAL skips instruction");

        check_reg(20, 32'd2047,      "ADDI maximum positive");
        check_reg(21, 32'hfffff800,  "ADDI minimum negative");
        check_reg(22, 32'h00001098,  "AUIPC at address 98");
        check_reg(23, 32'h12345000,  "LUI");
        check_reg(24, 32'd0,         "x0 read through ADDI");
        check_reg(25, 32'h000000b4,  "JALR target base");
        check_reg(26, 32'h000000b0,  "JALR link address");
        check_reg(27, 32'd10,        "JALR target instruction");

        check_mem(0, 32'h0005050a, "SB/SH byte lanes");
        check_mem(1, 32'd0,         "Unused memory word");

        if (DUT.rs1_data === 32'd0)
            $display("PASS: CPU architectural x0 read");
        else begin
            $display("FAIL: CPU architectural x0 read = %h",
                     DUT.rs1_data);
            errors = errors + 1;
        end

        if (pc_out === 32'h000000b8)
            $display("PASS: Reached terminal JAL loop");
        else begin
            $display("FAIL: Expected terminal loop PC B8, actual %h",
                     pc_out);
            errors = errors + 1;
        end

        $display("\n===== IMMEDIATE GENERATOR BOUNDARIES =====");

        check_imm(32'h80000013, 32'hfffff800,
                  "I-type minimum -2048");
        check_imm(32'h7ff00013, 32'h000007ff,
                  "I-type maximum +2047");
        check_imm(32'h80000023, 32'hfffff800,
                  "S-type minimum -2048");

        // Correct encoding for B-type minimum displacement -4096
        check_imm(32'h80000063, 32'hfffff000,
                  "B-type minimum -4096");

        check_imm(32'h7e000fe3, 32'h00000ffe,
                  "B-type maximum +4094");
        check_imm(32'h80000037, 32'h80000000,
                  "U-type sign bit");
        check_imm(32'h8000006f, 32'hfff00000,
                  "J-type minimum -1048576");

        $display("\n===== REGISTER FILE x0 TEST =====");

        @(negedge clk);
        rf_we = 1;
        rf_rd = 0;
        rf_wdata = 32'hdeadbeef;

        @(posedge clk);
        #1;
        rf_we = 0;
        rf_rs1 = 0;
        rf_rs2 = 0;
        #1;

        if ((rf_rdata1 === 32'd0) &&
            (rf_rdata2 === 32'd0))
            $display("PASS: x0 reads zero after attempted write");
        else begin
            $display("FAIL: x0 read outputs %h and %h",
                     rf_rdata1, rf_rdata2);
            errors = errors + 1;
        end

        $display("\n========================================");
        if (errors == 0)
            $display("ALL REGRESSION CHECKS PASSED");
        else
            $display("REGRESSION FAILED: %0d checks", errors);
        $display("========================================\n");

        $finish;
    end

    initial begin
        #2000;
        $display("ERROR: Testbench timeout");
        $finish;
    end

endmodule
