# RISC-V Single-Cycle CPU — RV32I

A modular, SystemVerilog-based implementation of a **single-cycle RISC-V processor** based on the RV32I instruction set, developed and verified using **AMD Xilinx Vivado 2022.2**.

The project focuses on processor architecture from the ground up: instruction fetch and decoding, register operations, ALU execution, control flow, memory access, and simulation-based verification.

## Table of Contents

- [Project Overview](#project-overview)
- [Features](#features)
- [Architecture](#architecture)
- [Project Structure](#project-structure)
- [Supported Instruction Categories](#supported-instruction-categories)
- [Verification and Testing](#verification-and-testing)
- [Verification Results](#verification-results)
- [Tools and Technologies](#tools-and-technologies)
- [How to Run the Project](#how-to-run-the-project)
- [Learning Outcomes](#learning-outcomes)
- [Future Improvements](#future-improvements)

---

## Project Overview

This project implements a **single-cycle CPU based on the RISC-V RV32I instruction format** using SystemVerilog.

In a single-cycle processor, an instruction is fetched, decoded, executed, and completed within one clock cycle. The processor uses dedicated hardware modules for instruction memory, control generation, register storage, arithmetic and logical operations, immediate generation, and data memory access.

The design was developed module by module and tested using directed SystemVerilog testbenches to verify individual components and integrated processor behavior.

### Project Goals

- Understand the internal working of a RISC-V processor.
- Implement processor datapath and control logic in SystemVerilog.
- Verify arithmetic, logical, branching, jump, and memory instructions.
- Test register-file behavior and the architectural zero register (`x0`).
- Validate immediate-generation and ALU/memory edge cases.
- Establish a foundation for further processor-architecture work.

## Features

- Modular SystemVerilog RTL design.
- Program-counter and instruction-fetch logic.
- Instruction decoding and control-signal generation.
- 32-entry integer register file with `x0` hardwired to zero.
- ALU supporting arithmetic, logical, shift, and comparison operations.
- Immediate generation for I-, S-, B-, U-, and J-type instructions.
- Conditional branches using signed and unsigned comparisons.
- `JAL` and `JALR` jump handling.
- Data-memory support for byte, halfword, and word accesses.
- Signed and unsigned load operations.
- Module-level and processor-level directed verification.
- Simulation-based verification in Vivado XSim.

## Architecture

The processor follows a conventional single-cycle datapath organization.

```text
                 +------------------+
                 | Program Counter  |
                 +--------+---------+
                          |
                          v
                 +------------------+
                 | Instruction     |
                 | Memory          |
                 +--------+---------+
                          |
                          v
                 +------------------+
                 | Control Unit     |
                 | Immediate Gen.   |
                 +--------+---------+
                          |
                          v
                 +------------------+
                 | Register File    |
                 +--------+---------+
                          |
                          v
                 +------------------+
                 | ALU / Branch    |
                 | Decision Logic   |
                 +--------+---------+
                          |
                 +--------+---------+
                 |                 |
                 v                 v
          +-------------+   +--------------+
          | Data Memory |   | Result / PC  |
          +------+------+   | Selection    |
                 |          +------+-------+
                 +-----------------+
                          |
                          v
                 Register Write-Back
```

*Conceptual datapath overview; the exact signal connections are defined by the RTL.*

### Instruction Execution Flow

1. **Fetch:** The program counter supplies the instruction address.
2. **Decode:** The control unit interprets the opcode and instruction fields.
3. **Read operands:** The register file supplies source-register values.
4. **Generate immediate:** The immediate generator constructs the instruction immediate.
5. **Execute:** The ALU performs arithmetic, logic, shifts, or comparisons.
6. **Access memory:** Load and store instructions access data memory when required.
7. **Write back:** The selected result is written to the destination register when enabled.
8. **Update PC:** Sequential execution, branch decisions, and jump instructions determine the next instruction address.

## Project Structure

The following reflects the folder and filenames shown in the project:

```text
Sim/
├── doc_results/
│   └── verification_singlecycle_riscv.docx
├── hexfiles/
│   ├── program_basic_cpu.hex
│   ├── program_branch_verification.hex
│   └── program_cpu_integration.hex
├── tbs/
│   ├── tb_alu_memory_edge_verification.sv
│   ├── tb_alu_verification.sv
│   ├── tb_basic_cpu_verification.sv
│   ├── tb_branch_verification.sv
│   ├── tb_control_flow_verification.sv
│   ├── tb_cpu_integration_verification.sv
│   ├── tb_immediate_control_memory_verification.sv
│   └── tb_module_verification.sv
├── Src/
│   ├── alu_control_unit.sv
│   ├── alu.sv
│   ├── control_unit.sv
│   ├── data_memory.sv
│   ├── immediate_generator.sv
│   ├── instruction_memory.sv
│   ├── program_counter.sv
│   ├── register_file.sv
│   └── single_cycle_top.sv
└── README.md
```

### Main RTL Modules

| Module | Responsibility |
|---|---|
| `single_cycle_top` | Integrates the processor datapath and control logic |
| `program_counter` | Maintains the current instruction address |
| `instruction_memory` | Supplies instructions from the initialized program |
| `control_unit` | Generates instruction-dependent control signals |
| `immediate_generator` | Produces I-, S-, B-, U-, and J-type immediates |
| `register_file` | Provides source operands and stores destination-register results |
| `alu_control_unit` | Selects the ALU operation from instruction fields and control inputs |
| `alu` | Performs arithmetic, logical, shift, and comparison operations |
| `data_memory` | Implements load/store data access |

## Supported Instruction Categories

The instruction categories below are represented in the RTL and verification programs. The list is not a claim that every possible RV32I encoding or architectural corner case has been verified.

### Arithmetic and Logical Instructions

- `ADD`, `SUB`
- `AND`, `OR`, `XOR`
- `SLT`, `SLTU`
- `ADDI`

### Shift Instructions

- `SLL`
- `SRL`
- `SRA`

Shift-related ALU-control decoding is also tested for `SLTIU`, `SRLI`, and `SRAI` encodings.

### Load Instructions

- `LB` — Load Byte, signed
- `LH` — Load Halfword, signed
- `LW` — Load Word
- `LBU` — Load Byte, unsigned
- `LHU` — Load Halfword, unsigned

### Store Instructions

- `SB` — Store Byte
- `SH` — Store Halfword
- `SW` — Store Word

### Branch Instructions

- `BEQ` — Branch if Equal
- `BNE` — Branch if Not Equal
- `BLT` — Branch if Less Than, signed
- `BGE` — Branch if Greater Than or Equal, signed
- `BLTU` — Branch if Less Than, unsigned
- `BGEU` — Branch if Greater Than or Equal, unsigned

### Jump and Upper-Immediate Instructions

- `JAL`
- `JALR`
- `LUI`
- `AUIPC`

## Verification and Testing

Verification was performed using eight directed SystemVerilog testbenches in Vivado XSim. The testbenches exercise individual modules, edge cases, instruction behavior, and integrated CPU execution.

### 1. ALU and Memory Edge Case Verification

**Testbench:** `tb_alu_memory_edge_verification.sv`

Tests ALU operations and edge cases, ALU-control decoding, and data-memory load behavior.

Covered cases include arithmetic and logical operations, signed/unsigned comparisons, shifts including boundary shift amounts, and byte/halfword load offsets and sign extension.

### 2. ALU Verification

**Testbench:** `tb_alu_verification.sv`

Checks the ALU's supported arithmetic, logical, shift, and comparison operations, including selected signed and unsigned input cases.

### 3. Basic CPU Verification

**Testbench:** `tb_basic_cpu_verification.sv`

Checks a basic instruction sequence covering immediate operations, `AUIPC`, `x0`/NOP behavior, unsupported-instruction safe behavior, a store, and terminal-loop PC behavior.

**Program file:** `program_basic_cpu.hex`

### 4. Branch Instruction Verification

**Testbench:** `tb_branch_verification.sv`

Checks taken and not-taken behavior for the six conditional branch instructions: `BEQ`, `BNE`, `BLT`, `BGE`, `BLTU`, and `BGEU`.

**Program file:** `program_branch_verification.hex`

### 5. Control Flow Instruction Verification

**Testbench:** `tb_control_flow_verification.sv`

Checks jump/control-flow behavior, including `JAL` and `JALR`, link-address behavior, and instruction-flow changes covered by the test program.

### 6. CPU Integration Verification

**Testbench:** `tb_cpu_integration_verification.sv`

Runs instruction sequences through the integrated single-cycle CPU and checks architectural results. The reported integration checks cover arithmetic/immediate instructions, loads and stores, branch conditions, jumps, register behavior, and related execution scenarios.

**Program file:** `program_cpu_integration.hex`

### 7. Immediate, Control, and Memory Verification

**Testbench:** `tb_immediate_control_memory_verification.sv`

Directly checks the immediate generator, control-unit outputs, register-file `x0` behavior, and selected data-memory/control safety cases. This is a module-level testbench and does not require an instruction HEX program.

### 8. Module-Level Verification

**Testbench:** `tb_module_verification.sv`

Performs direct checks of individual module behavior outside the full CPU execution flow.

## Verification Results

The testbenches listed above were run in simulation, and the user-reported results were passing. The verification document is stored at:

`Sim/doc_results/verification_singlecycle_riscv.docx`

The documented result summaries include:

| Verification area | Reported result |
|---|---|
| Branch regression | 12 passed, 0 failed |
| ALU and memory edge checks | 30 passed, 0 failed |
| Immediate-generator boundary checks | 7 passed, 0 failed |
| Register-file `x0` checks | Passed |
| CPU integration checks | All reported checks passed |
| Basic CPU verification | All checked results passed after the program file was corrected |
| Remaining listed testbenches | Reported passed |

**Verification scope:** These results represent the directed test cases that were run. Passing these tests does not establish complete RV32I compliance or prove every possible operand combination, encoding, exception, or architectural corner case.

## Tools and Technologies

- **HDL:** SystemVerilog
- **EDA tool:** AMD Xilinx Vivado 2022.2
- **Simulator:** Vivado XSim
- **Program initialization:** `$readmemh` with hexadecimal instruction files
- **Verification:** Directed SystemVerilog testbenches and simulation transcript checks
- **Target architecture:** RISC-V RV32I, 32-bit integer datapath

## How to Run the Project

1. Open the project in Vivado 2022.2.
2. Confirm that the RTL files in `Sim/Src/` are included in the project.
3. Add the desired testbench from `Sim/tbs/` under **Simulation Sources**.
4. For CPU program-based tests, ensure the relevant HEX file from `Sim/hexfiles/` is the one loaded by instruction memory.
5. Select the corresponding testbench as the simulation top.
6. Run **Run Behavioral Simulation**.
7. Inspect the simulation transcript for PASS/FAIL messages and the final test summary.

Some testbenches instantiate modules directly and do not need an instruction HEX file. For program-based tests, confirm the instruction-memory initialization path before running. If the path is hardcoded in the RTL, update it to the intended program file and restore it after the test.

## Learning Outcomes

This project provided practical experience with:

- RISC-V instruction formats and immediate encoding.
- Single-cycle datapath organization.
- Control-unit and ALU-control design.
- Register-file read/write behavior.
- Signed versus unsigned comparisons.
- Branch target and jump-link calculations.
- Byte-addressed memory accesses and byte lanes.
- SystemVerilog testbench development.
- Directed verification and debugging in Vivado.

## Future Improvements

Potential next steps include:

- Extending verification to additional instruction encodings and operand combinations.
- Improving reset and invalid-instruction behavior.
- Adding a more automated test execution flow.
- Developing or further verifying a five-stage pipelined implementation with pipeline registers, forwarding, and hazard detection.
- Comparing single-cycle and pipelined implementations in terms of timing and performance.

These are possible extensions, not prerequisites for the passing test results documented above.

## Conclusion

The project establishes a modular single-cycle RISC-V CPU and a set of directed simulation testbenches covering the tested ALU operations, control flow, memory behavior, immediate generation, register-file behavior, and integrated CPU execution.

The implementation and verification work provide a foundation for deeper study of processor datapaths, RTL verification, and pipelined CPU architecture.
---

## Author

**Name:** PEESU SWARANJITHREDDY  
**Department:** Electronics and Communication Engineering (ECE)  
**Institution:** National Institute of Technology, Rourkela  
**Project:** RISC-V Single-Cycle CPU — RV32I  
**Tools:** SystemVerilog, AMD Xilinx Vivado 2022.2

---

## License

This project is intended for educational and learning purposes.
