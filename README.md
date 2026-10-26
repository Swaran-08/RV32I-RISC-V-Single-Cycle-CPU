# RISC-V Single-Cycle Processor

A **32-bit RISC-V single-cycle processor** implemented in SystemVerilog using Xilinx Vivado 2022.2. This project focuses on understanding processor architecture, instruction execution, datapath design, control logic, and hardware verification.

The single-cycle processor is the first milestone of this project. A five-stage pipelined implementation is planned as a future extension.

## Overview

The processor is designed around the RV32I base instruction set and uses a modular hardware architecture. Each instruction is executed through the processor datapath in a single clock cycle.

The design includes instruction fetching, instruction decoding, register-file access, immediate generation, ALU operations, memory access, and write-back.

## Architecture

The main components of the processor are:

- **Program Counter (PC):** Maintains the address of the current instruction and selects the next instruction address.
- **Instruction Memory:** Supplies instructions to the processor.
- **Control Unit:** Generates control signals based on the instruction opcode and function fields.
- **Register File:** Provides two source operands and supports register write-back, with `x0` hardwired to zero.
- **Immediate Generator:** Extracts and sign-extends immediate values for supported instruction formats.
- **ALU Control:** Selects the appropriate ALU operation.
- **Arithmetic Logic Unit (ALU):** Performs arithmetic, logical, comparison, and shift operations.
- **Data Memory:** Supports load and store operations with byte, halfword, and word accesses.
- **Branch and Jump Logic:** Determines control flow and calculates branch or jump destinations.
- **Write-Back Logic:** Selects the result written to the destination register.

## Instruction Support

The implementation targets commonly used RV32I instruction classes, including:

| Instruction class | Examples |
|---|---|
| Arithmetic | `ADD`, `SUB`, `ADDI` |
| Logical | `AND`, `OR`, `XOR`, `ANDI`, `ORI`, `XORI` |
| Shift | `SLL`, `SRL`, `SRA`, `SLLI`, `SRLI`, `SRAI` |
| Comparison | `SLT`, `SLTU`, `SLTI`, `SLTIU` |
| Branch | `BEQ`, `BNE`, `BLT`, `BGE`, `BLTU`, `BGEU` |
| Jump | `JAL`, `JALR` |
| Load | `LB`, `LBU`, `LH`, `LHU`, `LW` |
| Store | `SB`, `SH`, `SW` |
| Upper immediate | `LUI`, `AUIPC` |

The instruction list describes the intended supported instruction classes. Full RV32I compliance, including exception and illegal-instruction handling, has not been established.

## Verification

The design has been tested using SystemVerilog testbenches in Vivado simulation.

Module-level regression checks have passed for the cases tested, including:

- ALU arithmetic and overflow boundaries
- Logical operations and shift edge cases
- Immediate generation boundary cases
- Register-file behavior and protection of register `x0`
- Control-unit default behavior
- Data-memory load sign extension and zero extension
- Word, halfword, and byte load behavior
- Invalid store control preserving memory contents

CPU-level instruction tests have also been performed. Verification of complete instruction coverage and all architectural edge cases remains ongoing.

## Tools and Technologies

- SystemVerilog
- Xilinx Vivado 2022.2
- Vivado Simulator
- Git and GitHub

## Project Structure

The repository will organize the project into the following areas:

- `single_cycle/rtl/` — Processor RTL modules
- `single_cycle/tb/` — Testbenches and regression tests
- `single_cycle/program.hex` — Machine-code program used for instruction-memory initialization
- `docs/` — Architecture diagrams and project documentation
- `pipeline/` — Planned five-stage pipelined implementation

The final directory structure will reflect the files committed to the repository.

## Future Work

- Complete instruction-level regression and edge-case verification
- Improve illegal-instruction and exception handling
- Develop a five-stage pipeline with IF, ID, EX, MEM, and WB stages
- Implement hazard detection and data forwarding
- Add pipeline stall and flush handling
- Compare single-cycle and pipelined processor performance
- Explore FPGA implementation and resource utilization

## Learning Objectives

This project provides hands-on experience with:

- RISC-V instruction encoding and execution
- Datapath and control-unit design
- RTL design using SystemVerilog
- Processor verification and debugging
- FPGA development workflows
- Pipelined processor architecture

---

**Project:** `riscv`  
**Processor target:** RV32I, 32-bit single-cycle architecture  
**Development environment:** Vivado 2022.2  
**Status:** Single-cycle implementation developed; verification and documentation ongoing; pipelining planned.
