# RV32IM RISC-V Processor with Hardware Multiplier Co-Processor

## 📌 Project Overview
This project implements a **32-bit RISC-V Processor (RV32IM)** using SystemVerilog. The core design is a single-cycle datapath integrated with a **multi-cycle Hardware Multiplier Co-processor**.

The primary engineering challenge (CEP) addressed in this project is the synchronization of a slow, iterative hardware unit (32-cycle multiplier) with a fast, single-cycle processor pipeline. This required the design of a **Hazard Detection Unit** to stall the CPU, freeze the Program Counter (PC), and manage data consistency during multiplication operations.

## 🚀 Key Features
*   **ISA Support:** RISC-V RV32I (Base Integer) + RV32M (Multiplication Extension).
*   **Architecture:** Single-Cycle Datapath for standard instructions; Multi-Cycle stall-based execution for multiplication.
*   **Multiplier Unit:**
    *   Radix-2 Shift-and-Add Algorithm.
    *   32-cycle latency.
    *   Supports `MUL`, `MULH`, `MULHSU`, and `MULHU`.
    *   Handles signed/unsigned operands and edge cases (e.g., `0x80000000`).
*   **Hazard Handling:** Dedicated control logic to stall the pipeline immediately upon detecting a multiply instruction.
*   **Memory:** Separate Instruction Memory (ROM) and Data Memory (RAM).

## 📂 File Structure

| Module File | Description |
| :--- | :--- |
| `top.sv` | **Top-Level Module.** Connects the Datapath, Control Unit, and Multiplier. Handles global stall logic. |
| `multiplier_coprocessor.sv` | **The Co-Processor.** Implements the 32-cycle shift-and-add logic and sign handling. |
| `multiplier_control.sv` | **Hazard Unit.** Detects MUL opcodes, asserts `stall_cpu`, and manages the FSM handshake. |
| `control.sv` | Wrapper for the main control logic. |
| `control_unit.sv` | Main decoder for Opcode to generate ALU, Memory, and Branch signals. |
| `alu_control.sv` | Decodes `funct3`/`funct7` to drive the ALU. |
| `alu.sv` | Arithmetic Logic Unit. Acts as a pass-through for the multiplier result when `mult_done` is high. |
| `register_file.sv` | 32x32-bit Register File with write-enable gating during stalls. |
| `program_counter.sv` | PC register with stall capability. |
| `instruction_memory.sv` | ROM initialized from `instructions.mem`. |
| `data_memory.sv` | RAM for Load/Store operations. |
| `imm_gen.sv` | Immediate value generator and sign extender. |
| `mux_2to1.sv` | Generic multiplexer for datapath routing. |
| `write_back_mux.sv` | Selects the final data to be written to the Register File. |
| `tb_top.sv` | Testbench for simulation and verification. |

## ⚙️ Architecture & Design Details

### 1. The Multiplier Co-Processor
The multiplier uses a sequential state machine (`IDLE` -> `BIT0`...`BIT31` -> `FINISH`).
*   **Input Capture:** To prevent "Ghost Data" (reading registers while they are changing), the multiplier captures inputs `a` and `b` using **combinational logic** immediately in the `IDLE` state.
*   **Sign Handling:** Inputs are converted to absolute values, multiplied as unsigned integers, and the sign is restored at the end based on the instruction type (`MULH` vs `MULHU`).

### 2. Pipeline Stalling (The CEP Solution)
Since the base processor is single-cycle, it expects an instruction to finish in 1 clock tick. The multiplier takes 33 ticks.
*   **Detection:** The `multiplier_control` unit detects opcode `0110011` with `funct7[0]=1`.
*   **Immediate Stall:** It asserts `stall_cpu = 1` **combinatorially**.
*   **Effect:**
    1.  `program_counter`: Freezes at the current address.
    2.  `register_file`: Write Enable is forced low to prevent corruption.
*   **Completion:** When the multiplier signals `done`, the stall is released, and `mult_write_pending` allows the result to be written to the destination register.

## 📝 Supported Instruction Set

| Type | Instructions | Description |
| :--- | :--- | :--- |
| **R-Type** | ADD, SUB, AND, OR, XOR, SLL, SRL, SRA, SLT, SLTU | Register-Register Arithmetic |
| **I-Type** | ADDI, ANDI, ORI, XORI, SLLI, SRLI, SRAI, SLTI, SLTIU | Immediate Arithmetic |
| **Loads** | LB, LH, LW, LBU, LHU | Load from Memory |
| **Stores** | SB, SH, SW | Store to Memory |
| **Branch** | BEQ, BNE, BLT, BGE, BLTU, BGEU | Conditional Branching |
| **Jump** | JAL, JALR | Unconditional Jumps |
| **M-Ext** | **MUL, MULH, MULHSU, MULHU** | **Hardware Multiplication** |
| **System** | LUI, AUIPC | Upper Immediate handling |

## 🧪 Verification

The processor has been verified using a comprehensive testbench (`tb_top.sv`) and hex code (`instructions.mem`).

### Critical Test Cases Passed:
1.  **Positive × Positive:** `10 × 20 = 200` (Verified)
2.  **Negative × Positive:** `-10 × 25 = -250` (Verified)
3.  **Negative × Negative:** `-8 × -6 = 48` (Verified)
4.  **Edge Case:** `0 × 0 = 0` (Verified)
5.  **Hazard Check:** Verified that the PC does not advance and the next instruction (`ADDI`) is not executed until the multiplication is complete.

## 🔧 How to Run Simulation

### Prerequisites
*   Icarus Verilog (`iverilog`)
*   GTKWave (for waveform viewing)

### Steps
1.  Save the source code files in a single directory.
2.  Create the `instructions.mem` file with the hex machine code.
3.  Compile the design:
    ```bash
    iverilog -g2012 -o cpu_sim *.sv
    ```
4.  Run the simulation:
    ```bash
    vvp cpu_sim
    ```
5.  View the waveforms (optional):
    ```bash
    gtkwave simulation.vcd
    ```
6.  Check `processor_debug.txt` for the cycle-by-cycle execution log.
