1. Purpose :
Brief, hardware-friendly descriptions of all core algorithms: Scheduler (detailed), Request Manager, Elevator FSM, Movement Planner, Emergency Handler, Top-level flow, and Test Plan. Parameterized by FLOORS and FLOOR_BITS = $clog2(FLOORS).


2. Parameters & Encodings :
// config.vh
parameter FLOORS      = 12;
parameter FLOOR_BITS  = $clog2(FLOORS);
parameter REQ_TYPES   = 3;               // CALL_UP, CALL_DOWN, CABIN
parameter REQ_BITS    = FLOORS * REQ_TYPES;

Request bit mapping:

bits [0 .. FLOORS-1]              = CALL_UP(f)
bits [FLOORS .. 2*FLOORS-1]      = CALL_DOWN(f)
bits [2*FLOORS .. 3*FLOORS-1]    = CABIN(f)

Top-level signals (suggested):

input  clk, rst;
input  [FLOORS-1:0] call_up, call_down;
input  [1:0][FLOORS-1:0] cabin_req;     // [elevator][floor]
input  emergency_button;

output [1:0][FLOOR_BITS-1:0] elev_pos;  // elevator positions
output [1:0:0] motor_dir;               // 0=IDLE,1=UP,2=DOWN


3. Elevator FSM (skeleton) :
// elevator_fsm.v (skeleton)
module elevator_fsm #(parameter FLOORS=12, FLOOR_BITS=$clog2(FLOORS))(
  input  clk, rst,
  input  [FLOORS*3-1:0] assigned_mask, // assigned request bits for this elevator
  input  [FLOOR_BITS-1:0] pos_in,
  input  emergency,
  output reg [1:0] state,               // IDLE/MOVING/ARRIVAL/DOOR_OPEN/EMERGENCY
  output reg [1:0] dir,                 // 0=IDLE,1=UP,2=DOWN
  output reg [FLOOR_BITS-1:0] target_floor
);
  // state encoding
  localparam IDLE=0, MOVING=1, ARRIVAL=2, DOOR_OPEN=3, EMERGENCY=4;

  // Minimal dwell timer and logic omitted for brevity
  always @(posedge clk) begin
    if (rst) begin
      state <= IDLE; dir <= 0; target_floor <= pos_in;
    end else if (emergency) begin
      state <= EMERGENCY;
      // stop motors, lock doors
    end else begin
      case (state)
        IDLE: begin
          if (assigned_mask != 0) begin
            // choose direction based on nearest assigned stop
            // set target_floor and dir
            state <= MOVING;
          end
        end
        MOVING: begin
          if (pos_in == target_floor) state <= ARRIVAL;
        end
        ARRIVAL: begin
          // open door, clear requests for this floor (handshake to request manager)
          state <= DOOR_OPEN;
        end
        DOOR_OPEN: begin
          // wait dwell; then if more assigned -> MOVING else IDLE
        end
      endcase
    end
  end
endmodule


4. Request Manager (atomic accept) :
// request_manager.v (concept)
module request_manager (
  input clk, rst,
  input [REQ_BITS-1:0] new_requests,         // OR of call_up/call_down/cabin inputs
  input [REQ_BITS-1:0] claim0, claim1,       // scheduler proposals
  output reg [REQ_BITS-1:0] pending_requests,
  output reg [REQ_BITS-1:0] assign0, assign1 // accepted assignments
);
  always @(posedge clk) begin
    if (rst) begin
      pending_requests <= 0;
      assign0 <= 0; assign1 <= 0;
    end else begin
      // register new requests
      pending_requests <= pending_requests | new_requests;

      // Arbitration: if both claim same bit -> tie-break
      // Simple rule: if both claim -> give to elevator with lower load/dir_align (tie-break handled outside)
      // For brevity, prefer claim0 on conflict (replace with proper arbiter)
      assign0 <= claim0 & pending_requests;
      assign1 <= (claim1 & pending_requests) & ~assign0;
      // clear pending bits that got assigned
      pending_requests <= pending_requests & ~(assign0 | assign1);
    end
  end
endmodule

Production: replace simple conflict rule with the tie-breaking logic described in Scheduler section.


5. Scheduler — algorithm + multi-cycle Verilog skeleton :

Cost function (recommended):

distance = abs(e_pos - r)
load = popcount(assigned_mask)
dir_align = (dir==UP && r>=pos && req up-like) || (dir==DOWN && r<=pos && req down-like) ? 0 : 1
reverse_penalty = (dir!=IDLE && serve_requires_reverse) ? 1 : 0

cost = distance*Wd + load*Wl + dir_align*Wdir + reverse_penalty*K_rev

Suggested weights: Wd=4, Wl=2, Wdir=8, K_rev=16.

Multi-cycle scan scheduler (synth-friendly):

// scheduler.v (multi-cycle scanner)
module scheduler #(parameter REQ_BITS=FLOORS*3)(
  input clk, rst, start_scan,
  input [REQ_BITS-1:0] pending_requests,
  input [FLOOR_BITS-1:0] elev_pos0, elev_pos1,
  input [1:0] elev_dir0, elev_dir1,
  input [REQ_BITS-1:0] assigned0, assigned1,
  output reg [REQ_BITS-1:0] claim0, claim1,
  output reg done
);
  reg [$clog2(REQ_BITS)-1:0] scan_idx;
  reg [7:0] age [0:REQ_BITS-1];

  // compute_cost(...) should be a small combinational function (adds, shifts)
  function [9:0] compute_cost;
    input [FLOOR_BITS-1:0] req_floor;
    input [FLOOR_BITS-1:0] epos;
    input [1:0] edir;
    input [4:0] load;
    input req_type; // 0=up/down-like, 1=cabin
    // implement distance, dir_align, reverse_penalty, weights
  endfunction

  always @(posedge clk) begin
    if (rst) begin
      scan_idx <= 0; claim0 <= 0; claim1 <= 0; done <= 0;
      // clear age[]
    end else begin
      if (start_scan) begin
        // reset local claims & begin scanning
        scan_idx <= 0; claim0 <= 0; claim1 <= 0; done <= 0;
      end
      // SCAN 1 request per cycle
      if (pending_requests[scan_idx]) begin
        // decode request -> floor r and type
        // cost0 = compute_cost(r, elev_pos0, elev_dir0, popcount(assigned0), type);
        // cost1 = compute_cost(r, elev_pos1, elev_dir1, popcount(assigned1), type);
        // if (age[scan_idx] >= AGE_THRESHOLD) force assign
        // if (cost0 <= cost1) claim0[scan_idx] <= 1; else claim1[scan_idx] <= 1;
      end
      // increment ages for pending bits
      // scan_idx++; if scan_idx == REQ_BITS-1 done <= 1;
    end
  end
endmodule

After done, present claim0/claim1 to request_manager for atomic accept.


6. Movement Planner (simple) :
// movement_planner (per-elevator)
function [FLOOR_BITS-1:0] select_next;
  input [REQ_BITS-1:0] assigned_mask;
  input [FLOOR_BITS-1:0] pos;
  input [1:0] dir;
  // if dir==UP: choose min(floor > pos)
  // if dir==DOWN: choose max(floor < pos)
  // if IDLE: choose nearest floor (min abs distance)
endfunction


7. Emergency Handler :
// emergency_handler (concept)
if (emergency_button) begin
  emergency_flag <= 1;
  // broadcast to all FSMs -> state = EMERGENCY
  // stop motors, optionally open doors
end
// clear via explicit operator reset or emergency_clear signal


8. Top-level Flow (summary) :
a. Buttons -> request_manager.pending_requests set
b. Scheduler scans pending -> produces claim0/claim1
c. Request_manager accepts claims atomically -> assign0/assign1, pending cleared
d. Movement_planner picks next target per elevator
e. Elevator FSM moves; on arrival clear floor bits (handshake to request_manager)
f. Emergency preempts (emergency_flag)


9. Test Plan (short) :
-Single cabin & floor calls (up/down)
-Simultaneous calls: verify correct assignment
-Opposing-direction requests while elevators moving
-Load balancing under burst requests
-Emergency assert mid-travel & resume
-Starvation test (age forcing)
-Record metrics: average wait, travel time, reversals count.

10. Notes & tuning :
-Use multi-cycle scan for FLOORS > 20
-Tune Wd/Wl/Wdir/K_rev in simulation
-Use AGE_THRESHOLD to avoid starvation
-Replace simple conflict rule in Request Manager with full arbiter (direction-align, load, distance, ID)