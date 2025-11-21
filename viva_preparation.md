# Viva Preparation Guide: Dual Elevator Control System

This document provides a comprehensive overview of the Dual Elevator System project, designed to help you prepare for a technical viva or presentation.

---

## 1. Project Overview

**High-Level Description:**

This project is a Verilog-based digital design of a **Dual Elevator Control System**. It simulates the operation of two elevators in a building with a configurable number of floors (default is 8). The system's core is a **centralized scheduler** that intelligently assigns floor calls to the most suitable elevator, aiming to minimize passenger wait times and optimize elevator travel.

**Key Features:**

*   **Dual Elevator Coordination:** Two independent elevators managed by one central scheduler.
*   **Intelligent Scheduling:** A priority-based algorithm assigns requests using a **cost function** that evaluates distance, direction, and current state.
*   **Finite State Machine (FSM):** Each elevator operates as a robust FSM, controlling its movement (IDLE, MOVING_UP, MOVING_DOWN) and door status (DOOR_OPEN).
*   **Parameterized and Scalable:** The number of floors can be easily changed in a central configuration file (`config.vh`), and the design automatically adapts.
*   **Emergency Handling:** A global `emergency_stop` signal can halt elevator operations safely.
*   **Comprehensive Simulation:** The project includes multiple testbenches to verify the functionality of individual modules and the integrated system.

---

## 2. System Architecture

The system is designed monolithically, where a top-level module connects all the sub-modules.

### System Block Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    DUAL ELEVATOR TOP                        │
│                                                             │
│  ┌──────────────┐         ┌──────────────┐                │
│  │  Elevator 1  │         │  Elevator 2  │                │
│  │     FSM      │         │     FSM      │                │
│  └──────┬───────┘         └──────┬───────┘                │
│         │                        │                         │
│         │  ┌──────────────────┐  │                         │
│         └──┤    Scheduler     ├──┘                         │
│            │ (Priority-Based) │                            │
│            └──────────────────┘                            │
│                                                             │
│  External Inputs: up_calls, down_calls, destinations        │
│  Outputs: positions, states, door status                    │
└─────────────────────────────────────────────────────────────┘
```

---

## 3. Core Modules Explained

### `dual_elevator_top.v`
This is the top-level module that instantiates and connects all other major components.

*   **Role:** Integrates the two `elevator_fsm` instances with the central `scheduler`.
*   **Request Handling:**
    *   It takes **external floor calls** (`up_calls`, `down_calls`) and passes them to the scheduler.
    *   It manages **internal destination requests** (from buttons inside the elevator) in persistent registers (`pending_dest_e1`, `pending_dest_e2`).
    *   It combines the scheduler's assignments with the internal destination requests before sending the final command to each elevator FSM.
*   **Connectivity:** It acts as the "main circuit board," wiring all inputs and outputs between the modules.

### `elevator_fsm.v`
This is the most important module for controlling a single elevator.

*   **Role:** Implements a **Finite State Machine (FSM)** to govern the elevator's behavior.
*   **FSM States (4 States):**
    1.  `S_IDLE`: The elevator is stationary with its door closed, waiting for a request. This is the default and safe state.
    2.  `S_MOVING_UP`: The elevator is traveling upwards.
    3.  `S_MOVING_DOWN`: The elevator is traveling downwards.
    4.  `S_DOOR_OPEN`: The elevator is at a floor, and the door is open for a fixed duration (controlled by `DOOR_TIMER_CYCLES`).

*   **Elevator FSM State Diagram:**

    ```
        ┌─────────────┐
        │    IDLE     │◄────────────┐
        └──────┬──────┘             │
               │                    │
               │ Request on        │ No requests
               │ another floor      │ after door close
               ▼                    │
        ┌─────────────┐             │
        │  MOVING_UP  ├─────────────┤
        │  MOVING_DN  │             │
        └──────┬──────┘             │
               │                    │
               │ Reached requested  │
               │ floor              │
               ▼                    │
        ┌─────────────┐             │
        │  DOOR_OPEN  ├─────────────┘
        └─────────────┘
            (Timer expires)
    ```

*   **State Transitions (Detailed):**
    *   **From `S_IDLE`:**
        *   If a request is present at the `current_floor`, transition to `S_DOOR_OPEN`.
        *   If there are requests `above` the `current_floor`, transition to `S_MOVING_UP`.
        *   If there are requests `below` the `current_floor`, transition to `S_MOVING_DOWN`.
    *   **From `S_DOOR_OPEN`:**
        *   After `door_timer` expires, if there are requests `above` and the elevator was moving up or idle, transition to `S_MOVING_UP`.
        *   After `door_timer` expires, if there are requests `below` and the elevator was moving down or idle, transition to `S_MOVING_DOWN`.
        *   If no further requests, transition to `S_IDLE`.
    *   **From `S_MOVING_UP`:**
        *   If `request_at_current_floor` is true, transition to `S_DOOR_OPEN`.
        *   If no more `has_request_above` but `has_request_below`, change direction to `S_MOVING_DOWN`.
        *   If no `has_request_above` and no `has_request_below`, transition to `S_IDLE`.
    *   **From `S_MOVING_DOWN`:**
        *   If `request_at_current_floor` is true, transition to `S_DOOR_OPEN`.
        *   If no more `has_request_below` but `has_request_above`, change direction to `S_MOVING_UP`.
        *   If no `has_request_above` and no `has_request_below`, transition to `S_IDLE`.
*   **`emergency_stop`:** When this signal is high, the FSM is forced into the `S_IDLE` state, doors are closed, and movement is stopped, ensuring safety.

### `scheduler.v`
This is the "brain" of the system. It decides which elevator should handle a specific floor call.

*   **Role:** To efficiently assign `up_calls` and `down_calls` to either Elevator 1 or Elevator 2.
*   **Algorithm:** The scheduler uses a **cost function** (`calculate_cost`) to evaluate how "expensive" it would be for each elevator to service a new request. The request is assigned to the elevator with the **lowest cost**.
*   **Cost Function Explained (`calculate_cost`):**
    *   The cost is an integer value calculated based on several factors:
    1.  **Distance Cost:** The absolute difference between the elevator's current floor and the request floor. This is the most significant factor.
    2.  **State Penalty:** An elevator that is `IDLE` is preferred. A penalty is added if the elevator is already busy (moving or door open). This encourages using idle elevators first.
    3.  **Direction Mismatch Penalty:** A heavy penalty is applied if an elevator is moving in the opposite direction of a request (e.g., moving up but the request is on a floor below it). This prevents elevators from inefficiently changing direction.
*   **Request Latching:** The scheduler uses internal registers (`pending_up_calls`, `pending_down_calls`) to "latch" or store floor requests. A request remains pending until one of the elevators signals that it has been serviced.

### `config.vh`
A simple but critical file for project scalability.

*   **Role:** Provides global, project-wide parameters using the `` `define `` directive.
*   **Key Parameters:**
    *   `` `NUM_FLOORS ``: Defines the total number of floors. Changing this one value rescales the entire project's logic (e.g., bus sizes).
    *   `` `FLOOR_BITS ``: Automatically calculated based on `NUM_FLOORS`.
    *   `` `DOOR_TIMER_CYCLES` `` / `` `MOVE_TIMER_CYCLES` ``: Control the timing of the simulation, making it easy to adjust.
*   **Benefit:** Avoids "magic numbers" in the code, making it more readable, maintainable, and easy to configure.

---

## 4. Simulation and Testing

The project is thoroughly tested using Verilog testbenches (`/tb` directory), which are executed by shell scripts (or Windows batch files) (`/simulation` directory). Each testbench focuses on verifying specific functionalities.

*   **`elevator_tb.v` (Single Elevator Testbench):**
    *   **Purpose:** This testbench isolates and verifies the correct behavior of a single `elevator_fsm` module.
    *   **What it does:** It provides simulated clock, reset, and various floor `requests` to the `elevator_fsm`. It then monitors the elevator's outputs (`current_floor`, `state`, `door_open`, `moving_up`, `moving_down`, `request_serviced`) to ensure it transitions through its states correctly, stops at requested floors, opens and closes doors for the specified duration, and handles direction changes.
    *   **Scenarios Tested:** Single floor requests, multiple sequential requests, requests above and below the elevator, door open/close timing.
    *   **Verification:** Checks if the elevator correctly reaches requested floors and services them.

*   **`scheduler_tb.v` (Scheduler Testbench):**
    *   **Purpose:** This testbench focuses solely on validating the `scheduler.v` module's logic.
    *   **What it does:** It simulates the inputs that the scheduler would receive from the `dual_elevator_top` module (e.g., `up_calls`, `down_calls`, current states and floors of both elevators). It then asserts different call patterns and checks if the scheduler's outputs (`requests_to_e1`, `requests_to_e2`) correctly assign the calls to the appropriate elevator based on the cost function and priority rules.
    *   **Scenarios Tested:** Assigning calls to idle elevators, calls for elevators moving in the same direction, calls for elevators moving in opposite directions, balancing load between elevators.
    *   **Verification:** Ensures the scheduling algorithm correctly prioritizes and distributes requests.

*   **`dual_elevator_tb.v` (Dual Elevator System Testbench):**
    *   **Purpose:** This is the **full system integration test**. It verifies the interaction between all modules (`dual_elevator_top`, `elevator_fsm` instances, `scheduler`).
    *   **What it does:** It instantiates the `dual_elevator_top` module and generates complex sequences of external floor calls and internal destination requests. It monitors the overall system behavior, including both elevators' movements, door operations, and how requests are handled collaboratively.
    *   **Scenarios Tested:** Simultaneous calls, heavy traffic scenarios, emergency stop handling, destination requests from inside elevators, comprehensive system response under various load conditions.
    *   **Verification:** Confirms that the entire dual elevator system functions as a cohesive unit according to specifications.

*   **`visualization_tb.v` (Visualization Testbench):**
    *   **Purpose:** This testbench is specifically designed to generate waveform data that is useful for the Python-based visualization tools.
    *   **What it does:** It runs a typical simulation scenario and outputs extensive debug information, often including all internal signals, to a VCD file.
    *   **Scenarios Tested:** A representative simulation of the dual elevator system's operation.
    *   **Verification:** Primarily generates data for visualization, ensuring that the necessary signals are dumped for analysis.

The testbenches use `$display` to print simulation progress to the console and `$dumpvars`/`$dumpfile` to generate a VCD (Value Change Dump) file. This file can be opened with a waveform viewer like **GTKWave** to visually debug and analyze signal behavior over time.

---

## 5. Potential Viva Questions & Answers

### General Verilog Questions

**Q1: What is the difference between blocking (`=`) and non-blocking (`<=`) assignments? Why is it important?**
*   **Answer:** **Blocking assignments (`=`)** are executed sequentially in a procedural block. The next statement is only executed after the current one is complete. They are typically used for **combinational logic** in an `always @(*)` block. **Non-blocking assignments (`<=`)** are scheduled to occur at the end of the current time step. All right-hand-side expressions are evaluated first, and then the assignments are made simultaneously. They are used for **sequential logic** in a clocked `always @(posedge clk)` block to avoid race conditions and model flip-flops correctly.
*   **In this project:** We use non-blocking (`<=`) in our sequential `always @(posedge clk)` blocks for state registers (`state_reg`) and floor counters (`current_floor_reg`). We use blocking (`=`) in our combinational `always @(*)` blocks, for example, to determine the `next_state`.

**Q2: What is an `always` block? What are the different types you used?**
*   **Answer:** An `always` block is a procedural block that describes how signals should be updated. We used two types:
    1.  `always @(posedge clk or posedge reset)`: This describes **sequential logic**. The block is triggered only on the rising edge of the clock or reset signal. It's used to model flip-flops and registers.
    2.  `always @(*)`: This describes **combinational logic**. The block is triggered whenever any signal on the right-hand side of an assignment inside it changes. It's used to model logic gates and decision logic, like determining the `next_state` in our FSM.

**Q3: What is the purpose of `` `include "config.vh" ``?**
*   **Answer:** The `` `include `` directive is a pre-processor command that literally pastes the content of the specified file (`config.vh`) into the current file before compilation. We use it to import global definitions from `config.vh`, such as `` `NUM_FLOORS ``. This allows us to maintain a single source of truth for key parameters, making the design scalable and easy to modify without changing the Verilog modules themselves.

### FSM Design Questions

**Q4: Is your elevator FSM a Mealy or Moore machine? Why?**
*   **Answer:** Our FSM is primarily a **Moore machine**. In a Moore machine, the outputs depend *only on the current state*. Our main outputs like `moving_up`, `moving_down`, and `door_open` are driven directly by the state (`state_reg` or `next_state`). For example, `moving_up` is high *only when* the state is `S_MOVING_UP`. The outputs are not directly affected by the inputs in the same clock cycle. This leads to a safer, more stable design, as it prevents momentary glitches in the inputs from propagating directly to the outputs.

**Q5: How did you define the states in your FSM?**
*   **Answer:** We used the `parameter` keyword to give meaningful names to our state encodings (e.g., `parameter S_IDLE = 2'd0;`). This makes the code much more readable and maintainable than using "magic numbers" for states. We used 2 bits to encode our 4 states.

### Project-Specific Questions

**Q6: Explain your scheduling algorithm. How does an elevator get assigned a request?**
*   **Answer:** Our scheduler uses a **cost-based algorithm**. For every pending floor call, it calculates a "cost" for each of the two elevators to service that call. The elevator with the **lowest cost** wins the assignment. The cost is determined by a function that considers three main factors:
    1.  **Distance:** How far the elevator is from the requested floor.
    2.  **State:** An idle elevator has a lower cost than a busy one.
    3.  **Direction:** A heavy penalty is added if the elevator is moving away from the request, making it very "expensive" to service.
    This ensures that idle elevators are prioritized and that busy elevators only pick up requests that are conveniently "on the way."

**Q7: How does your system handle an emergency stop?**
*   **Answer:** There is a global `emergency_stop` input signal connected to each `elevator_fsm` module. Inside the FSM's main sequential block, this signal has the highest priority after `reset`. If `emergency_stop` is asserted:
    *   The FSM is forced into the `S_IDLE` state.
    *   All movement outputs (`moving_up`, `moving_down`) are de-asserted.
    *   The `door_open` signal is de-asserted to ensure the doors remain closed for safety.
    *   The elevator's current floor position is preserved, so it knows where it is when the emergency is over and can resume normal operations.

**Q8: In `dual_elevator_top.v`, you have `pending_dest_e1` for buttons inside the elevator. Why is this needed? Why not just feed it directly to the FSM?**
*   **Answer:** The `destination_e1` input is a pulse that is high for only one clock cycle when a passenger presses a button. If we fed this pulse directly to the FSM, the FSM would only "see" the request for that single cycle. If the elevator was busy, it might miss the request. By using the `pending_dest_e1` register, we **latch** the request. The request is stored in this register and stays asserted until the elevator FSM signals that it has serviced that specific floor. This creates a persistent memory for internal destination requests.

**Q9: How do you prevent a race condition when clearing a pending request in the scheduler?**
*   **Answer:** The request clearing mechanism is designed to be safe. The `elevator_fsm` emits a single-cycle pulse `request_serviced` when its door starts to open at a floor. The scheduler uses this pulse to clear the corresponding `pending_up_calls` or `pending_down_calls`. Since the pulse is only one cycle long and is synchronized to the same clock, there is a clear and deterministic sequence of events: the elevator decides to service a floor, and on the next cycle, the scheduler sees the "serviced" pulse and clears the request.

### Algorithm Questions

**Q10: What is a potential weakness of your current scheduling algorithm? How could it be improved?**
*   **Answer:** A potential weakness is that it evaluates each floor request independently in a `for` loop, which can lead to sub-optimal global behavior in heavy traffic. For example, it might assign two nearby calls to two different elevators when one elevator could have serviced both more efficiently.
*   **Improvement 1 (Look-ahead):** A more advanced scheduler could look at the entire set of pending requests and plan a more optimal route for each elevator, considering clusters of requests.
*   **Improvement 2 (Load Balancing):** The current algorithm doesn't explicitly consider the number of pending requests already assigned to an elevator. An improvement would be to add a "load" factor to the cost function, making it more "expensive" for an already busy elevator to accept new requests.
*   **Improvement 3 (Energy Optimization):** The algorithm could be modified to penalize direction changes more heavily or to favor shorter movements to reduce simulated energy consumption.
