# Project: Multiply-Accumulate (MAC) Unit Design
This project implements a **Multiply-Accumulate (MAC) Unit** in **Bluespec SystemVerilog (BSV)**
## Overview

The Multiply-Accumulate (MAC) Unit combines multiplication and addition into a single operation:  
\[
\text{MAC Output} = (A \times B) + C
\]

The project includes the following main modules:
- **8-bit Full Adder**: A basic full adder for handling 8-bit arithmetic.
- **32-bit Full Adder**: A full adder for performing 32-bit addition operations.
- **16x16 Bit Multiplier**: A Booth's algorithm-based multiplier for multiplying two 16-bit numbers.
- **Integer MAC**: A Multiply-Accumulate unit for 8-bit integers.
- **Floating Point MAC**: A Multiply-Accumulate unit for floating point numbers (bfloat16 and fp32).
The design avoids using built-in `+` or `*` operators, relying instead on algorithmic approaches to implement the arithmetic operations.

---
## Supported Features

- **Two modes of operation**:
  - **Integer Mode (S1):** `(A: int8, B: int8, C: int32) → MAC: int32`
  - **Floating-Point Mode (S2):** `(A: bf16, B: bf16, C: fp32) → MAC: fp32`
- **Floating-point calculations**:
  - IEEE 754 compliant operations.
  - Rounding mode: `ROUND_TO_NEAREST`.

## Modules

### 1. **8-Bit Ripple Carry Adder (mk8Fadder)**
- Implements an **8-bit adder** with carry propagation.
- **Inputs**: Two 8-bit operands (`A` and `B`) and carry-in (`Cin`).
- **Output**: 9-bit result (`Sum` + `Cout`).

### 2. **32-Bit Ripple Carry Adder (mkFulladder)**
- Extends the 8-bit adder to a **32-bit ripple carry adder**.
- **Inputs**: Two 32-bit operands and carry-in.
- **Output**: 33-bit result (`Sum` + `Cout`).

### 3. **16x16-Bit Booth's Multiplier (mkMul)**
- Multiplies two signed 16-bit integers using **Booth's Algorithm**.
- **Output**: 32-bit signed product.

### 4. **Integer Multiply-Accumulate (mkIntmac)**
- Performs the MAC operation:  
  \[
  \text{Result} = (A \times B) + C
  \]
- **Inputs**:
  - `A`, `B`: 8-bit signed integers.
  - `C`: 32-bit integer accumulator.
- **Output**: 32-bit integer MAC result.

### 5. **Floating-Point Multiply-Accumulate (mkFpmac)**
- Performs MAC operation for **bf16 (16-bit)** inputs and produces an **fp32 (32-bit)** result.
- **Features**:
  - Supports IEEE 754 floating-point arithmetic.
  - Handles multiplication and addition with normalization and rounding.
