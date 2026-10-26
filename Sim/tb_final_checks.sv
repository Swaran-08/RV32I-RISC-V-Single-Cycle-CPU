
`timescale 1ns / 1ps

module tb_final_checks;

    logic clk = 0;
    integer errors = 0;
    integer i;

    // =================================================
    // GROUP 1: REGISTER FILE
    // =================================================

    logic rf_we;
    logic [4:0] rs1, rs2, rd;
    logic [31:0] wd, rdata1, rdata2;

    register_file RF (
        .clk(clk),
        .reg_write(rf_we),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .write_data(wd),
        .read_data1(rdata1),
        .read_data2(rdata2)
    );

    // =================================================
    // GROUP 2: IMMEDIATE GENERATOR
    // =================================================

    logic [31:0] instr, imm_out;

    immediate_generator IG (
        .instr(instr),
        .imm_out(imm_out)
    );

    // Construct legal-format instructions with selected
    // immediate values for independent testing.

    function automatic [31:0] enc_i(input logic [11:0] v);
        enc_i = {v, 5'd0, 3'b000, 5'd1, 7'b0010011};
    endfunction

    function automatic [31:0] enc_s(input logic [11:0] v);
        enc_s = {v[11:5], 5'd2, 5'd1, 3'b010,
                 v[4:0], 7'b0100011};
    endfunction

    function automatic [31:0] enc_b(input logic [12:0] v);
        enc_b = {v[12], v[10:5], 5'd2, 5'd1, 3'b000,
                 v[4:1], v[11], 7'b1100011};
    endfunction

    function automatic [31:0] enc_j(input logic [20:0] v);
        enc_j = {v[20], v[10:1], v[11], v[19:12],
                 5'd1, 7'b1101111};
    endfunction

    task automatic check_imm(
        input logic [31:0] instruction_value,
        input logic [31:0] expected,
        input string name
    );
        begin
            instr = instruction_value;
            #1;
            if (imm_out === expected)
                $display("PASS: %s = %08h", name, imm_out);
            else begin
                $display("FAIL: %s got %08h expected %08h",
                         name, imm_out, expected);
                errors = errors + 1;
            end
        end
    endtask

    // =================================================
    // GROUP 3: CONTROL UNIT AND DATA MEMORY SAFETY
    // =================================================

    logic [6:0] opcode;
    logic [2:0] funct3;
    logic reg_write, mem_read, mem_write, mem_to_reg;
    logic alu_src, branch, jump, lui, auipc;
    logic [1:0] alu_op;
    logic [2:0] load_type, store_type;

    control_unit CU (
        .opcode(opcode),
        .funct3(funct3),
        .reg_write(reg_write),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .mem_to_reg(mem_to_reg),
        .alu_src(alu_src),
        .alu_op(alu_op),
        .branch(branch),
        .jump(jump),
        .lui(lui),
        .auipc(auipc),
        .load_type(load_type),
        .store_type(store_type)
    );

    logic dm_read, dm_write;
    logic [2:0] dm_load_type, dm_store_type;
    logic [31:0] dm_addr, dm_wdata, dm_rdata;

    data_memory DM (
        .clk(clk),
        .mem_read(dm_read),
        .mem_write(dm_write),
        .load_type(dm_load_type),
        .store_type(dm_store_type),
        .addr(dm_addr),
        .write_data(dm_wdata),
        .read_data(dm_rdata)
    );

    always #5 clk = ~clk;

    task automatic check_control_safe(input string name);
        begin
            #1;
            if (!reg_write && !mem_read && !mem_write &&
                !mem_to_reg && !branch && !jump && !lui && !auipc)
                $display("PASS: %s", name);
            else begin
                $display("FAIL: %s asserted unsafe control", name);
                errors = errors + 1;
            end
        end
    endtask

    initial begin

        // Initialize module inputs.
        rf_we = 0;
        rs1 = 0;
        rs2 = 0;
        rd = 0;
        wd = 0;

        instr = 0;

        opcode = 0;
        funct3 = 0;

        dm_read = 0;
        dm_write = 0;
        dm_load_type = 3'b010;
        dm_store_type = 3'b010;
        dm_addr = 0;
        dm_wdata = 0;

        // Deterministic register-file initialization.
        for (i = 0; i < 32; i = i + 1)
            RF.array[i] = 0;

        DM.mem[0] = 32'h12345678;

        repeat (2) @(negedge clk);

        // =============================================
        // GROUP 1: x0 PROTECTION
        // =============================================

        $display("\n=== GROUP 1: REGISTER FILE ===");

        @(negedge clk);
        rf_we = 1;
        rd = 0;
        wd = 32'hDEADBEEF;

        @(posedge clk);
        #1;

        if (RF.array[0] === 32'b0)
            $display("PASS: Write to x0 ignored");
        else begin
            $display("FAIL: x0 array changed");
            errors = errors + 1;
        end

        rs1 = 0;
        rs2 = 0;
        #1;

        if (rdata1 === 0 && rdata2 === 0)
            $display("PASS: x0 reads zero on both ports");
        else begin
            $display("FAIL: x0 read ports");
            errors = errors + 1;
        end

        @(negedge clk);
        rf_we = 0;

        // =============================================
        // GROUP 2: IMMEDIATE GENERATOR
        // =============================================

        $display("\n=== GROUP 2: IMMEDIATES ===");

        check_imm(enc_i(12'h800), 32'hFFFFF800,
                  "I-type minimum");
        check_imm(enc_i(12'h7FF), 32'h000007FF,
                  "I-type maximum");

        check_imm(enc_s(12'h800), 32'hFFFFF800,
                  "S-type minimum");
        check_imm(enc_s(12'h7FF), 32'h000007FF,
                  "S-type maximum");

        check_imm(enc_b(13'h1000), 32'hFFFFF000,
                  "B-type minimum");
        check_imm(enc_b(13'h0FFE), 32'h00000FFE,
                  "B-type maximum");

        check_imm(enc_j(21'h100000), 32'hFFF00000,
                  "J-type minimum");
        check_imm(enc_j(21'h0FFFFE), 32'h000FFFFE,
                  "J-type maximum");

        check_imm({20'h80000, 5'd1, 7'b0110111},
                  32'h80000000, "U-type high bit");
        check_imm({20'h7FFFF, 5'd1, 7'b0110111},
                  32'h7FFFF000, "U-type maximum positive");

        // =============================================
        // GROUP 3: CONTROL / MEMORY SAFETY
        // =============================================

        $display("\n=== GROUP 3: CONTROL SAFETY ===");

        // Unsupported load funct3 = 011.
        opcode = 7'b0000011;
        funct3 = 3'b011;
        check_control_safe("Unsupported load funct3");

        // Unsupported store funct3 = 011.
        opcode = 7'b0100011;
        funct3 = 3'b011;
        check_control_safe("Unsupported store funct3");

        // Unsupported opcode.
        opcode = 7'b1111111;
        funct3 = 3'b000;
        check_control_safe("Unsupported opcode");

        // Directly test invalid store_type in data memory.
        // A write request with an unsupported type must not
        // modify the existing memory word.
        @(negedge clk);
        dm_addr = 0;
        dm_wdata = 32'hDEADBEEF;
        dm_store_type = 3'b111;
        dm_write = 1;

        @(posedge clk);
        #1;

        if (DM.mem[0] === 32'h12345678)
            $display("PASS: Invalid store type preserves memory");
        else begin
            $display("FAIL: Invalid store changed memory to %08h",
                     DM.mem[0]);
            errors = errors + 1;
        end

        @(negedge clk);
        dm_write = 0;

        // =============================================
        // FINAL SUMMARY
        // =============================================

        $display("\n================================");
        if (errors == 0)
            $display("ALL FINAL CHECKS PASSED");
        else
            $display("TEST FAILED: %0d error(s)", errors);

        $display("================================\n");
        $finish;
    end

endmodule
