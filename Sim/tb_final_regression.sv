
`timescale 1ns / 1ps

module tb_final_regression;

    integer errors = 0;
    integer i;

    logic [31:0] a, b, result;
    logic [3:0] alu_code;

    logic clk = 0;
    logic rf_we;
    logic [4:0] rs1, rs2, rd;
    logic [31:0] wd, r1, r2;

    logic [31:0] instr, imm;
    logic [6:0] opcode;
    logic [2:0] funct3;

    logic reg_write, mem_read, mem_write, mem_to_reg;
    logic alu_src, branch, jump, lui, auipc;
    logic [1:0] alu_op;
    logic [2:0] load_type, store_type;

    logic dm_read, dm_write;
    logic [2:0] dm_lt, dm_st;
    logic [31:0] dm_addr, dm_wd, dm_rd;

    alu U_ALU (
        .a(a), .b(b),
        .alu_control(alu_code),
        .result(result)
    );

    register_file U_RF (
        .clk(clk), .reg_write(rf_we),
        .rs1(rs1), .rs2(rs2), .rd(rd),
        .write_data(wd),
        .read_data1(r1), .read_data2(r2)
    );

    immediate_generator U_IG (
        .instr(instr), .imm_out(imm)
    );

    control_unit U_CU (
        .opcode(opcode), .funct3(funct3),
        .reg_write(reg_write),
        .mem_read(mem_read), .mem_write(mem_write),
        .mem_to_reg(mem_to_reg), .alu_src(alu_src),
        .alu_op(alu_op), .branch(branch), .jump(jump),
        .lui(lui), .auipc(auipc),
        .load_type(load_type), .store_type(store_type)
    );

    data_memory U_DM (
        .clk(clk), .mem_read(dm_read),
        .mem_write(dm_write),
        .load_type(dm_lt), .store_type(dm_st),
        .addr(dm_addr), .write_data(dm_wd),
        .read_data(dm_rd)
    );

    always #5 clk = ~clk;

    task automatic check(
        input logic [31:0] got,
        input logic [31:0] expected,
        input string name
    );
        begin
            if (got === expected)
                $display("PASS: %s = %08h", name, got);
            else begin
                $display("FAIL: %s got %08h expected %08h",
                         name, got, expected);
                errors = errors + 1;
            end
        end
    endtask

    task automatic alu_check(
        input logic [31:0] x, y,
        input logic [3:0] op,
        input logic [31:0] expected,
        input string name
    );
        begin
            a = x;
            b = y;
            alu_code = op;
            #1;
            check(result, expected, name);
        end
    endtask

    task automatic imm_check(
        input logic [31:0] instruction_value,
        input logic [31:0] expected,
        input string name
    );
        begin
            instr = instruction_value;
            #1;
            check(imm, expected, name);
        end
    endtask

    initial begin
        a = 0; b = 0; alu_code = 0;
        rf_we = 0; rs1 = 0; rs2 = 0; rd = 0; wd = 0;
        instr = 0;
        opcode = 0; funct3 = 0;
        dm_read = 0; dm_write = 0;
        dm_lt = 0; dm_st = 0;
        dm_addr = 0; dm_wd = 0;

        for (i = 0; i < 32; i = i + 1)
            U_RF.array[i] = 0;

        for (i = 0; i < 256; i = i + 1)
            U_DM.mem[i] = 0;

        $display("\n=== GROUP 1: ALU REGRESSION ===");

        alu_check(32'h7fffffff, 1, 0, 32'h80000000,
                  "ADD signed boundary");
        alu_check(32'hffffffff, 1, 0, 0,
                  "ADD wraparound");
        alu_check(0, 1, 1, 32'hffffffff,
                  "SUB underflow");
        alu_check(32'h80000000, 1, 1, 32'h7fffffff,
                  "SUB boundary");
        alu_check(32'hffffffff, 1, 5, 1,
                  "SLT signed");
        alu_check(32'hffffffff, 1, 6, 0,
                  "SLTU unsigned");
        alu_check(32'haaaaaaaa, 32'h55555555, 4,
                  32'hffffffff, "XOR");
        alu_check(32'hf0f0aa55, 32'h0ff00ff0, 2,
                  32'h00f00a50, "AND");
        alu_check(32'hf0f0aa55, 32'h0ff00ff0, 3,
                  32'hfff0aff5, "OR");
        alu_check(1, 0, 7, 1, "SLL shift 0");
        alu_check(1, 31, 7, 32'h80000000, "SLL shift 31");
        alu_check(32'h80000000, 31, 8, 1, "SRL shift 31");
        alu_check(32'h80000000, 31, 9, 32'hffffffff,
                  "SRA shift 31");
        alu_check(1, 32, 7, 1, "Shift uses low five bits");

        $display("\n=== GROUP 2: IMMEDIATE GENERATOR ===");

        imm_check(32'h80000093, 32'hfffff800,
                  "I immediate minimum");
        imm_check(32'h7ff00093, 32'h000007ff,
                  "I immediate maximum");
        imm_check(32'h00000093, 0, "I immediate zero");
        imm_check(32'h800000b7, 32'h80000000,
                  "U immediate high bit");
        imm_check(32'h7ffff0b7, 32'h7ffff000,
                  "U immediate maximum");

        $display("\n=== GROUP 3: REGISTER FILE ===");

        @(negedge clk);
        rf_we = 1; rd = 0; wd = 32'hdeadbeef;

        @(posedge clk);
        #1;
        check(U_RF.array[0], 0, "Write to x0 ignored");

        @(negedge clk);
        rd = 5; wd = 32'h12345678;

        @(posedge clk);
        #1;
        check(U_RF.array[5], 32'h12345678,
              "Normal register write");

        @(negedge clk);
        rf_we = 0; rs1 = 5; rs2 = 0;
        #1;
        check(r1, 32'h12345678, "Register read port 1");
        check(r2, 0, "Register x0 read port 2");

        $display("\n=== GROUP 4: CONTROL DEFAULTS ===");

        opcode = 7'b1111111;
        funct3 = 3'b000;
        #1;

        if (!reg_write && !mem_read && !mem_write &&
            !mem_to_reg && !branch && !jump && !lui && !auipc)
            $display("PASS: Unsupported opcode disables writes");
        else begin
            $display("FAIL: Unsupported opcode control defaults");
            errors = errors + 1;
        end

        // Unsupported load funct3 must disable load/writeback.
        opcode = 7'b0000011;
        funct3 = 3'b011;
        #1;

        if (!reg_write && !mem_read && !mem_to_reg)
            $display("PASS: Unsupported load funct3");
        else begin
            $display("FAIL: Unsupported load funct3");
            errors = errors + 1;
        end

        // Unsupported store funct3 must disable memory writes.
        opcode = 7'b0100011;
        funct3 = 3'b011;
        #1;

        if (!mem_write)
            $display("PASS: Unsupported store funct3");
        else begin
            $display("FAIL: Unsupported store funct3");
            errors = errors + 1;
        end

        $display("\n=== GROUP 5: DATA MEMORY ===");

        @(negedge clk);
        dm_addr = 0;
        dm_wd = 32'h80ff7f01;
        dm_st = 3'b010;
        dm_write = 1;

        @(posedge clk);
        #1;

        @(negedge clk);
        dm_write = 0;
        dm_read = 1;

        dm_lt = 3'b010;
        dm_addr = 0;
        #1;
        check(dm_rd, 32'h80ff7f01, "LW");

        dm_lt = 3'b000;
        dm_addr = 0;
        #1;
        check(dm_rd, 32'h00000001, "LB offset 0");

        dm_addr = 1;
        #1;
        check(dm_rd, 32'h0000007f, "LB offset 1");

        dm_addr = 2;
        #1;
        check(dm_rd, 32'hffffffff, "LB offset 2");

        dm_addr = 3;
        #1;
        check(dm_rd, 32'hffffff80, "LB offset 3");

        dm_lt = 3'b100;
        dm_addr = 2;
        #1;
        check(dm_rd, 32'h000000ff, "LBU offset 2");

        dm_addr = 3;
        #1;
        check(dm_rd, 32'h00000080, "LBU offset 3");

        dm_lt = 3'b001;
        dm_addr = 0;
        #1;
        check(dm_rd, 32'h00007f01, "LH lower half");

        dm_addr = 2;
        #1;
        check(dm_rd, 32'hffff80ff, "LH upper half");

        dm_lt = 3'b101;
        dm_addr = 2;
        #1;
        check(dm_rd, 32'h000080ff, "LHU upper half");

        // Invalid store type must not modify memory.
        @(negedge clk);
        dm_read = 0;
        dm_write = 1;
        dm_st = 3'b111;
        dm_wd = 32'hdeadbeef;

        @(posedge clk);
        #1;
        check(U_DM.mem[0], 32'h80ff7f01,
              "Invalid store preserves memory");

        @(negedge clk);
        dm_write = 0;

        $display("\n=== FINAL SUMMARY ===");

        if (errors == 0)
            $display("ALL MODULE CHECKS PASSED");
        else
            $display("REGRESSION FAILED: %0d errors", errors);

        $finish;
    end

endmodule
