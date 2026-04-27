<h1 align="center"> AHB Bus (Advanced High-performance Bus) - Verilog RTL Design </h1>

<p align="center">
<img src="https://img.shields.io/badge/Protocol-AMBA%20AHB-blue?style=for-the-badge"/>
<img src="https://img.shields.io/badge/Design-RTL-orange?style=for-the-badge"/>
<img src="https://img.shields.io/badge/Language-Verilog-green?style=for-the-badge"/>
<img src="https://img.shields.io/badge/Stage-Bus%20Design-purple?style=for-the-badge"/>
</p>

<p align="center">
<img src="https://img.shields.io/badge/Status-Completed-success?style=flat-square"/>
<img src="https://img.shields.io/badge/Type-On--Chip%20Protocol-blue?style=flat-square"/>
<img src="https://img.shields.io/badge/Role-High%20Speed%20Interconnect-informational?style=flat-square"/>
</p>

---

<p align="center">
Implementation of <b>AMBA AHB</b> along with a simple <b>AHB Master</b>, enabling pipelined, burst-based high-speed on-chip communication and integration with APB.
</p>

---

# Overview

- High-performance on-chip bus protocol  
- Fully pipelined (Address + Data overlap)  
- Supports single and burst transfers  
- Configurable data width and address width  
- Used for CPU, memory, and high-bandwidth peripherals  

---

# AHB Architecture

```mermaid
flowchart LR
    CPU[AHB Master] --> AHB[AHB BUS]
    AHB --> MEM[Memory]
    AHB --> BRIDGE[AHB-APB Bridge]
    BRIDGE --> APB
```

---

# Core Components

- **Master (Manager)**  
  Initiates transfers (address + control generation)

- **Slave (Subordinate)**  
  Responds with data, ready, and response signals  

- **Decoder**  
  Selects slave based on address  

- **Multiplexer**  
  Routes read data and response back to master  

---

# Transfer Mechanism

```mermaid
flowchart LR
    ADDR[Address Phase] --> DATA[Data Phase]
    DATA --> NEXT[Next Transfer]
```

- Address phase = 1 cycle (cannot be extended)  
- Data phase = 1 or more cycles  
- Overlapping enables **pipelining**  

---

# Basic Transfer Operation

- Master drives address + control  
- Slave samples in next cycle  
- Data phase follows  
- HREADY controls completion  

- Write → Master drives HWDATA  
- Read → Slave drives HRDATA  

---

# Types of Transfers

## Read Transfer

<img width="550" height="160" alt="image" src="https://github.com/user-attachments/assets/3e006a9a-42b9-41a2-b882-9a336998116f" />

- HWRITE = 0  
- Slave → HRDATA  
- Master samples when HREADY = 1  

**Condition:**
- Valid when HTRANS = NONSEQ / SEQ  
- Data valid only when HREADY = 1  

## Write Transfer

<img width="546" height="173" alt="image" src="https://github.com/user-attachments/assets/0c69948a-fb72-49cc-8b3c-3b22303acf45" />

- HWRITE = 1  
- Master → HWDATA  
- Slave captures data  

**Condition:**
- Address phase → control valid  
- Data phase → data valid  


## Read (No Wait State)

<img width="619" height="175" alt="image" src="https://github.com/user-attachments/assets/945ed536-e999-4a25-8f7f-2adf4d406c04" />

- No stall from slave  
- HREADY = 1 continuously  

**Condition:**
- Completes in 2 cycles  
- Address + Data  

## Write (No Wait State)

<img width="506" height="167" alt="image" src="https://github.com/user-attachments/assets/af18fcc6-8955-4269-ab22-62263315de24" />

- Immediate completion  

**Condition:**
- HREADY = 1  
- No wait insertion  


## Burst / Multi Transfer

<img width="741" height="205" alt="image" src="https://github.com/user-attachments/assets/efe4849a-2de6-4097-afcc-67df15d3a2c2" />

- Multiple transfers in sequence  

**Condition:**
- First → NONSEQ  
- Remaining → SEQ  
- Address auto-increment  

---

## HTRANS Encoding

| HTRANS | Type |
|--------|------|
| 00 | IDLE |
| 01 | BUSY |
| 10 | NONSEQ |
| 11 | SEQ |

- IDLE → no transfer  
- BUSY → pipeline stall inside burst  
- NONSEQ → first transfer  
- SEQ → remaining burst transfers  

---

# Burst Types (HBURST)

| HBURST | Type |
|--------|------|
| 000 | SINGLE |
| 001 | INCR |
| 010 | WRAP4 |
| 011 | INCR4 |
| 100 | WRAP8 |
| 101 | INCR8 |
| 110 | WRAP16 |
| 111 | INCR16 |

- Incrementing → sequential addresses  
- Wrapping → wraps at boundary  

---

# Transfer Size (HSIZE)

| HSIZE | Size |
|-------|------|
| 000 | 8-bit |
| 001 | 16-bit |
| 010 | 32-bit |
| 011 | 64-bit |
| 100 | 128-bit |

---

# Wait States

- Controlled using HREADY  
- HREADY = 0 → insert wait  
- Extends data phase  

---

# Locked Transfers

- Controlled using HMASTLOCK  
- Ensures atomic operation  

**Condition:**
- Lock asserted → no interruption  
- Used for critical sections  

---

# Signal Description

## Global

| Signal | Description |
|--------|------------|
| HCLK | Clock |
| HRESETn | Active low reset |

## Master Signals

| Signal | Description |
|--------|------------|
| HADDR | Address |
| HWRITE | Read/Write |
| HTRANS | Transfer type |
| HSIZE | Transfer size |
| HBURST | Burst type |
| HWDATA | Write data |

## Slave Signals

| Signal | Description |
|--------|------------|
| HRDATA | Read data |
| HREADY | Transfer complete |
| HRESP | Response (OKAY/ERROR) |

---

# Response Types

| HRESP | Meaning |
|-------|--------|
| 0 | OKAY |
| 1 | ERROR |

---

# AHB Bus Implementation

```verilog
assign s_haddr     = m_haddr;
assign s_hwrite    = m_hwrite;
assign s_hsize     = m_hsize;
assign s_hburst    = m_hburst;
assign s_hprot     = m_hprot;
assign s_htrans    = m_htrans;
assign s_hmastlock = m_hmastlock;
assign s_hwdata    = m_hwdata;

assign m_hrdata = s_hrdata;
assign m_hready = s_hready;
assign m_hresp  = s_hresp;
```

- Direct pass-through interconnect  
- Can be extended to multi-slave system  

---

# AHB Master FSM

```mermaid
flowchart LR
    IDLE --> WRITE
    WRITE --> READ
    READ --> READ
```

- Generates control signals  
- Handles sequencing  
- Sync using HREADY  

---

# Data Flow

```mermaid
flowchart LR
    CPU --> AHB
    AHB --> BRIDGE
    BRIDGE --> APB
    APB --> UART
    UART --> DONE[Data Stored]
```

---

# Key Features

- Pipelined high-speed communication  
- Burst transfer capability  
- Efficient bandwidth utilization  
- Scalable architecture  

---

# Role in SoC

- Core high-speed backbone  
- Connects CPU and memory  
- Interfaces with APB for peripherals  

---

<p align="center"><b>
AHB enables high-performance, pipelined, and scalable communication in SoC designs, forming the backbone for efficient system-level integration.
</p>
  
---
