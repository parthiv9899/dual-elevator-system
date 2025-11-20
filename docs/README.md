# 🛗 Dual Elevator Control System using Verilog  
### Smart, Scalable, Priority-Based Elevator Scheduling with Full Simulation

---

## 📌 Project Overview

This project implements a **dual elevator control system** in **Verilog**, focusing on efficiency, safety, and scalability. It supports **any number of floors** (6, 8, 10, 12, 20, 50…) using parameterized hardware design. The system features:

- Smart priority scheduling  
- Efficient movement planning  
- Multi-request queueing  
- Emergency stop handling  
- Modular FSM architecture  
- Full simulation using Icarus Verilog + GTKWave  
- Optional web-based visualization  

The goal is to create a **generalized**, **future-ready**, and **energy-optimized** elevator system suitable for multi-story buildings.

## 🎯 Key Features

### 🛗 1. Dual Elevator Operation
Two elevators run independently but are coordinated through a central scheduling module:
- Adaptive request assignment  
- Load balancing  
- Collision-free movement  
- Reduced passenger wait times  

---

### ⚙️ 2. Priority-Based Request Scheduling
A custom algorithm selects the optimal elevator for each request based on:

- Current direction  
- Relative distance to request floor  
- Elevator load (pending requests)  
- Energy cost of changing direction  

**Priority rules:**

1. Direction-aligned requests  
2. Closest request  
3. Least-loaded elevator  
4. Minimal movement overhead  

---

### 🌍 3. Scalable Floor System (Any Number of Floors)

Supports **arbitrary number of floors**, not limited to powers of 2.

Set floors in `config.vh`:

```verilog
parameter FLOORS = 12;
parameter FLOOR_BITS = $clog2(FLOORS);

Examples:

10 floors → 4 bits

12 floors → 4 bits

20 floors → 5 bits

50 floors → 6 bits

No redesign required.

🚨 4. Emergency Stop + Safe Resume

Immediate halt on emergency

Doors lock for safety

State and direction preserved

System resumes automatically after reset

Transparent integration into FSM

🧵 5. Multi-Request Queueing

Each elevator maintains:

Request register

min_request & max_request

Request clearing logic

Central request manager ensures:

No request is lost

No starvation

Fair distribution

⚡ 6. Energy-Efficient Movement Planning

Movement planner ensures:

Minimal reversing

Minimized total travel distance

Direction persistence

Intelligent path selection


---

# ✅ **README PART 3 — MORE FEATURES + VISUALIZATION**  
```markdown
### 🔬 7. Full Simulation Pipeline
Using **Icarus Verilog** + **GTKWave**, the system supports:

- Multi-floor test scenarios  
- Parallel elevator movement  
- Request bursts  
- Emergency stop cases  
- Scheduler arbitration visualization  

---

### 🌐 8. Web-Based Visualization (Optional)  
A clean, animated UI to display real-time elevator movement using:

- HTML  
- CSS  
- JavaScript  
- Python/Node.js backend for simulation data 

## 🏗️ Project Architecture

dual-elevator-system/
│
├── src/
│ ├── elevator_fsm.v # FSM for each elevator
│ ├── request_manager.v # Handles user requests
│ ├── scheduler.v # Priority-based scheduler
│ ├── movement_planner.v # Optimizes elevator movement
│ ├── emergency_handler.v # Handles emergency stop logic
│ ├── dual_elevator_top.v # Top-level integration
│ └── config.vh # Floor count and system parameters
│
├── tb/
│ ├── elevator_tb.v # Single elevator testbench
│ ├── scheduler_tb.v # Scheduler testing
│ └── dual_elevator_tb.v # Full system testbench
│
├── simulation/
│ ├── wave.vcd # Waveform output
│ ├── run_sim.sh # Compile + run script
│ └── output/ # Extra simulation logs
│
├── diagrams/
│ ├── block_diagram.png
│ ├── fsm_elevator.png
│ ├── fsm_scheduler.png
│ └── priority_flowchart.png
│
├── docs/
│ ├── README.md
│ ├── requirements.md
│ ├── algorithms.md
│ └── simulation_results.md
│
└── visualization/
├── web/
│ ├── index.html
│ ├── style.css
│ └── app.js
└── api/
└── sim_api.py

## 🧠 Core Functional Modules

### 1️⃣ elevator_fsm.v  
Controls:
- UP/DOWN movement  
- Door operations  
- Idle state  
- Serving floor requests  
- Direction switching logic  

---

### 2️⃣ request_manager.v  
Responsible for:
- Registering floor requests  
- Updating request buffer  
- Clearing requests  
- Tracking min/max request indices  

---

### 3️⃣ scheduler.v  
The “brain” of the system:
- Assigns requests to elevators  
- Computes cost function  
- Checks direction, distance, and load  
- Prevents conflicts  

---

### 4️⃣ movement_planner.v  
Ensures:
- Energy-efficient movement  
- Minimal reversing  
- Direction persistence  
- Smooth motion  

---

### 5️⃣ emergency_handler.v  
Handles:
- Emergency stop button  
- Door locking  
- Safe resume  
- Flag-based control  

---

### 6️⃣ dual_elevator_top.v  
Integrates:
- Two elevator FSMs  
- Scheduler  
- Request manager  
- Movement planner  
- Emergency logic  

## 📐 System Diagrams (To Be Added)
- Block diagram (system architecture)  
- Elevator FSM  
- Scheduler FSM  
- Priority algorithm flowchart  

Place images in `/diagrams` folder.

---

## 🚀 Future Enhancements
- Predictive AI-based scheduling  
- FPGA hardware implementation  
- IoT dashboard integration  
- Fault detection and sensor monitoring  
- 3D graphical visualization  

---

## 👥 Team
Aadi Mehta
Chintan Thacker
Fenil Patel
Parthiv Karangiya
