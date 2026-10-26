
module single_cycle_top (
    input  logic        clk,
    input  logic        reset,
    output logic [31:0] pc_out
);

    // --------------------------------------------------
    // Internal signals
    // --------------------------------------------------

    logic [31:0] instruction;
    logic [31:0] next_pc;
    logic [31:0] pc_plus4;

    logic [31:0] rs1_data;
    logic [31:0] rs2_data;
    logic [31:0] immediate;

    logic [31:0] alu_a;
    logic [31:0] alu_b;
    logic [31:0] alu_result;

    logic [31:0] memory_read_data;
    logic [31:0] writeback_data;

    logic [4:0] rs1;
    logic [4:0] rs2;
    logic [4:0] rd;

    logic [3:0] alu_control_signal;

    logic reg_write;
    logic mem_read;
    logic mem_write;
    logic mem_to_reg;
    logic alu_src;
    logic [1:0] alu_op;

    logic branch;
    logic jump;
    logic lui;
    logic auipc;

    logic [2:0] load_type;
    logic [2:0] store_type;

    logic branch_taken;
    logic pc_select;

    // --------------------------------------------------
    // Instruction fields
    // --------------------------------------------------

    assign rs1 = instruction[19:15];
    assign rs2 = instruction[24:20];
    assign rd  = instruction[11:7];

    assign pc_plus4 = pc_out + 32'd4;

    // --------------------------------------------------
    // Program Counter
    // --------------------------------------------------

    assign pc_select = (branch && branch_taken) || jump;

    program_counter PC (
        .clk(clk),
        .reset(reset),
        .pc_select(pc_select),
        .pc_next(next_pc),
        .pc_out(pc_out)
    );

    // --------------------------------------------------
    // Instruction Memory
    // --------------------------------------------------

    instr_mem IMEM (
        .addr(pc_out),
        .instr(instruction)
    );

    // --------------------------------------------------
    // Control Unit
    // --------------------------------------------------

    control_unit CU (
        .opcode(instruction[6:0]),
        .funct3(instruction[14:12]),

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

    // --------------------------------------------------
    // Immediate Generator
    // --------------------------------------------------

    immediate_generator IG (
        .instr(instruction),
        .imm_out(immediate)
    );

    // --------------------------------------------------
    // Register File
    // --------------------------------------------------

    register_file RF (
        .clk(clk),
        .reg_write(reg_write),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .write_data(writeback_data),
        .read_data1(rs1_data),
        .read_data2(rs2_data)
    );

    // --------------------------------------------------
    // ALU input selection
    // --------------------------------------------------

    always_comb begin
        alu_a = rs1_data;
        alu_b = rs2_data;

        if (auipc)
            alu_a = pc_out;

        if (lui)
            alu_a = 32'b0;

        if (alu_src)
            alu_b = immediate;  
    end

    // --------------------------------------------------
    // ALU Control
    // is_immediate prevents ADDI's immediate bit 30
    // from being decoded as the SUB operation.
    // --------------------------------------------------

    alu_control ALU_CTRL (
        .alu_op(alu_op),
        .funct3(instruction[14:12]),
        .funct7_bit5(instruction[30]),
        .is_immediate(instruction[6:0] == 7'b0010011),
        .alu_control(alu_control_signal)
    );

    // --------------------------------------------------
    // ALU
    // --------------------------------------------------

    alu ALU (
        .a(alu_a),
        .b(alu_b),
        .alu_control(alu_control_signal),
        .result(alu_result)
    );

    // --------------------------------------------------
    // Branch decision
    // --------------------------------------------------

    always_comb begin
        branch_taken = 1'b0;

        if (branch) begin
            case (instruction[14:12])
                3'b000: branch_taken =
                            (rs1_data == rs2_data); // BEQ

                3'b001: branch_taken =
                            (rs1_data != rs2_data); // BNE

                3'b100: branch_taken =
                            ($signed(rs1_data) < $signed(rs2_data)); // BLT

                3'b101: branch_taken =
                            ($signed(rs1_data) >= $signed(rs2_data)); // BGE

                3'b110: branch_taken =
                            (rs1_data < rs2_data); // BLTU

                3'b111: branch_taken =
                            (rs1_data >= rs2_data); // BGEU

                default: branch_taken = 1'b0;
            endcase
        end
    end

    // --------------------------------------------------
    // Next PC selection
    // --------------------------------------------------

    always_comb begin
        next_pc = pc_plus4;

        if (branch && branch_taken)
            next_pc = pc_out + immediate;

        if (jump) begin
            if (instruction[6:0] == 7'b1100111)
                next_pc = {alu_result[31:1], 1'b0}; // JALR
            else
                next_pc = pc_out + immediate;       // JAL
        end
    end

    // --------------------------------------------------
    // Data Memory
    // --------------------------------------------------

    data_memory DMEM (
        .clk(clk),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .load_type(load_type),
        .store_type(store_type),
        .addr(alu_result),
        .write_data(rs2_data),
        .read_data(memory_read_data)
    );

    // --------------------------------------------------
    // Writeback selection
    // --------------------------------------------------

    always_comb begin
        writeback_data = alu_result;

        if (mem_to_reg)
            writeback_data = memory_read_data;

        if (jump)
            writeback_data = pc_plus4;

        if (lui)
            writeback_data = immediate;

        if (auipc)
            writeback_data = pc_out + immediate;
    end

endmodule
