# RISC-V Single-Cycle CPU — RV32I

A modular, SystemVerilog-based implementation of a **single-cycle RISC-V processor**, developed and verified using **AMD Xilinx Vivado 2022.2**.

The project focuses on understanding processor architecture from the ground up, including instruction decoding, register operations, ALU execution, control flow, memory access, and verification through simulation.

---

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

The design was developed module by module and tested using directed simulation testbenches to verify individual components and integrated processor behavior.

### Project Goals

- Understand the internal working of a RISC-V processor.
- Implement processor datapath and control logic in SystemVerilog.
- Verify arithmetic, logical, branching, jump, and memory instructions.
- Test register-file behavior and the architectural zero register.
- Validate important immediate-generation and ALU edge cases.
- Establish a tested foundation for a future five-stage pipelined CPU.

---

## Features

- Modular SystemVerilog RTL design.
- Program-counter and instruction-fetch logic.
- Instruction decoding and control-signal generation.
- 32-entry integer register file with x0 hardwired to zero.
- ALU supporting arithmetic, logical, shift, and comparison operations.
- Immediate generation for I-, S-, B-, U-, and J-type instructions.
- Conditional branches using signed and unsigned comparisons.
- JAL and JALR jump handling.
- Data-memory support for byte, halfword, and word accesses.
- Signed and unsigned load operations.
- Directed module-level and processor-level regression tests.
- Simulation-based verification in Vivado.

---

## Architecture

The processor follows the conventional single-cycle datapath organization.

```text
                 +------------------+
                 | Program Counter  |
                 +--------+---------+
                          |
                          v
                 +------------------+
                 | Instruction      |
                 | Memory           |
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
                 | ALU / Branch     |
                 | Decision Logic   |
                 +--------+---------+
                          |
                 +--------+---------+
                 |                  |
                 v                  v
          +-------------+    +-------------+
          | Data Memory |    | Result / PC |
          +------+------+    | Selection   |
                 |           +------+------+
                 +------------------+
                          |
                          v
                 Register Write-Back
```

*Conceptual datapath overview; the exact signal connections are defined by the RTL.*

### Instruction Execution Flow

1. **Fetch:** The program counter supplies the address of the instruction.
2. **Decode:** The control unit interprets the opcode and instruction fields.
3. **Read operands:** The register file supplies source-register values.
4. **Generate immediate:** The immediate generator extracts and sign-extends or arranges the immediate field.
5. **Execute:** The ALU performs arithmetic, logic, shifts, or comparisons.
6. **Access memory:** Load and store instructions access data memory when required.
7. **Write back:** The selected result is written to the destination register when enabled.
8. **Update PC:** Sequential execution, branch decisions, and jump instructions determine the next instruction address.

---

## Project Structure

The following is the logical organization of the design. Exact filenames may vary with the Vivado project setup.

```text
riscv_swaran/
├── src/
│   ├── single_cycle_top.sv
│   ├── program_counter.sv
│   ├── instr_mem.sv
│   ├── control_unit.sv
│   ├── immediate_generator.sv
│   ├── register_file.sv
│   ├── alu_control.sv
│   ├── alu.sv
│   └── data_memory.sv
│
├── sim/
│   ├── tb_extended_verification.sv
│   ├── tb_branch_regression.sv
│   ├── tb_final_edge_regression.sv
│   ├── program.hex
│   └── program_branch.hex
│
└── README.md
```

The tree illustrates the intended organization; retain the actual filenames and directories in your Vivado project.

### Main Modules

| Module | Responsibility |
|---|---|
| `single_cycle_top` | Integrates the processor datapath and control logic |
| `program_counter` | Maintains the current instruction address |
| `instr_mem` | Supplies instructions from the initialized program |
| `control_unit` | Generates instruction-dependent control signals |
| `immediate_generator` | Produces I-, S-, B-, U-, and J-type immediates |
| `register_file` | Provides source operands and stores destination-register results |
| `alu_control` | Selects the ALU operation from instruction fields |
| `alu` | Performs arithmetic, logical, shift, and comparison operations |
| `data_memory` | Implements load/store data access |

---

## Supported Instruction Categories

The following categories are exercised by the implemented RTL and verification programs.

### 1. Arithmetic and Logical Instructions

- `ADD`, `SUB`
- `AND`, `OR`, `XOR`
- `SLT`, `SLTU`
- `ADDI`

### 2. Shift Instructions

- `SLL`
- `SRL`
- `SRA`

Shift-related ALU control decoding is also tested for `SLTIU`, `SRLI`, and `SRAI` encodings.

### 3. Load Instructions

- `LB` — Load Byte, signed
- `LH` — Load Halfword, signed
- `LW` — Load Word
- `LBU` — Load Byte, unsigned
- `LHU` — Load Halfword, unsigned

### 4. Store Instructions

- `SB` — Store Byte
- `SH` — Store Halfword
- `SW` — Store Word

### 5. Branch Instructions

- `BEQ` — Branch if Equal
- `BNE` — Branch if Not Equal
- `BLT` — Branch if Less Than, signed
- `BGE` — Branch if Greater Than or Equal, signed
- `BLTU` — Branch if Less Than, unsigned
- `BGEU` — Branch if Greater Than or Equal, unsigned

### 6. Jump and Upper-Immediate Instructions

- `JAL`
- `JALR`
- `LUI`
- `AUIPC`

**Scope note:** This list describes the instructions and categories exercised in the current design and tests. It is not a claim that every RV32I instruction, encoding, exception, or architectural corner case has been verified.

---

## Verification and Testing

Verification was performed using directed SystemVerilog testbenches in Vivado XSim. The tests cover individual ALU and memory behavior, branch conditions, and integrated CPU execution.

### Test 1 — Branch Regression

**Testbench:** `tb_branch_regression.sv`

The branch regression verifies taken and not-taken behavior for all six implemented conditional branch types.

| Instruction | Taken case | Not-taken case |
|---|---:|---:|
| BEQ | Pass | Pass |
| BNE | Pass | Pass |
| BLT | Pass | Pass |
| BGE | Pass | Pass |
| BLTU | Pass | Pass |
| BGEU | Pass | Pass |

**Result: 12 passed, 0 failed.**

### Test 2 — ALU and Memory Edge Regression

**Testbench:** `tb_final_edge_regression.sv`

This suite directly tests the ALU, ALU control, and data memory modules.

**ALU operations tested**
- ADD, SUB, AND, OR, XOR
- Signed SLT and unsigned SLTU
- SLL, SRL, and SRA

**Edge and control checks**
- Signed comparison with a negative operand.
- Shift by zero and shift by 31.
- Arithmetic right shift of a negative value.
- ALU-control decoding for SLTIU, SRLI, and SRAI.
- Additional ALU result checks for unsigned comparison and right-shift behavior.

**Memory-load checks**
- LBU at byte offsets 0, 1, 2, and 3.
- LHU at offsets 0 and 2.
- Signed LB at offset 3.
- Signed LH at offset 2.

**Result: 30 passed, 0 failed.**

### Test 3 — CPU Integration Regression

**Testbench:** `tb_extended_verification.sv`

This testbench runs the processor with instructions loaded from `program.hex` and checks architectural state and execution results.

The integration regression covers:

- Basic ADDI operations and register results.
- LB, LH, LW, LBU, and LHU behavior.
- SB and SH byte-lane effects and memory contents.
- Taken and not-taken branch scenarios.
- Signed and unsigned branch comparisons.
- JAL link-address generation and skipped-instruction behavior.
- JALR link address, jump target, and target-instruction execution.
- Maximum positive and minimum negative ADDI immediates.
- AUIPC and LUI results.
- Reads involving x0 and preservation of the architectural zero-register behavior.
- Terminal-loop PC behavior.

**Result: All reported CPU integration checks passed.**

### Test 4 — Immediate Generator Boundaries

The immediate generator was tested independently for seven boundary cases.

| Immediate type | Test case | Expected behavior |
|---|---|---|
| I-type | Minimum: -2048 | Correct sign extension |
| I-type | Maximum: +2047 | Correct positive immediate |
| S-type | Minimum: -2048 | Correct sign extension |
| B-type | Minimum: -4096 | Correct branch immediate |
| B-type | Maximum: +4094 | Correct branch immediate |
| U-type | Sign bit set | Correct upper-immediate construction |
| J-type | Minimum: -1048576 | Correct jump immediate |

**Result: 7 passed, 0 failed.**

### Test 5 — Register File x0 Verification

The testbench attempts to write to register x0 and verifies that reading it still returns zero.

The integrated CPU test also checks x0-related architectural behavior.

**Result: The reported x0 checks passed.**

---

## Verification Results

The collected simulation evidence reports the following results:

| Verification suite | Passed | Failed | Status |
|---|---:|---:|---|
| Branch regression | 12 | 0 | PASS |
| ALU and memory edge regression | 30 | 0 | PASS |
| Immediate generator boundaries | 7 | 0 | PASS |
| Register-file x0 test | 1 | 0 | PASS |
| CPU integration regression | All reported checks | 0 reported | PASS |

The immediate-generator and x0 checks are included within the broader CPU integration testbench, so these rows represent **test categories, not independent totals to be added together**.

### Overall Outcome

**All documented regression suites completed successfully with no reported failures.**

The tests provide evidence of correct behavior for the tested instruction cases, ALU operations, immediate boundaries, memory accesses, branch decisions, jump behavior, and x0 protection.

Passing directed tests does not, by itself, establish complete ISA compliance or prove that every possible operand combination and instruction encoding is correct.

---

## Tools and Technologies

- **HDL:** SystemVerilog
- **EDA tool:** AMD Xilinx Vivado 2022.2
- **Simulator:** Vivado XSim
- **Program initialization:** `$readmemh` with a hexadecimal instruction file
- **Verification:** Directed testbenches and simulation transcript checks
- **Target architecture:** RISC-V, 32-bit integer datapath

---

## How to Run the Project

1. Open the project in Vivado 2022.2.
2. Confirm that the SystemVerilog design modules are included in the project.
3. Add the required testbench under **Simulation Sources**.
4. Ensure that `program.hex` is available at the file path used by the instruction-memory module.
5. Select the relevant testbench as the simulation top.
6. Run **Run Behavioral Simulation**.
7. Inspect the simulation transcript for PASS/FAIL messages and the final regression summary.

For the branch regression, ensure that the instruction-memory module reads the branch test program. If it uses a hardcoded `program.hex` path, copy the intended branch program to that path or update the path before simulation, then restore the integration program for the CPU regression.

The standalone ALU/memory edge regression instantiates its modules directly and does not require the CPU's instruction program.

---

## Learning Outcomes

This project provided practical experience with:

- RISC-V instruction formats and immediate encoding.
- Single-cycle datapath organization.
- Control-unit and ALU-control design.
- Register-file read/write behavior.
- Signed versus unsigned comparisons.
- Branch target and jump-link calculations.
- Byte-addressed memory accesses and little-endian byte lanes.
- SystemVerilog testbench development.
- Directed regression testing and debugging in Vivado.

---

## Future Improvements

Potential next steps include:

- Extending verification to additional instruction encodings and operand combinations.
- Improving reset and invalid-instruction behavior.
- Adding broader automated regression coverage.
- Developing a five-stage pipelined implementation with pipeline registers, forwarding, and hazard detection.
- Comparing the single-cycle and pipelined implementations in terms of timing and performance.

These are possible extensions, not prerequisites for the successful test results documented above.

---

## Conclusion

The project establishes a working, modular single-cycle RISC-V CPU and a documented simulation-based verification suite. The tested design covers core arithmetic and logical execution, branching, jumps, memory operations, immediate generation, and register-file x0 behavior.

The implementation serves as a foundation for deeper study of processor datapaths, RTL verification, and pipelined CPU architecture.
