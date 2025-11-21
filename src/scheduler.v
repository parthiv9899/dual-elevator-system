// src/scheduler.v
// This module is the central brain for the dual elevator system.
// It arbitrates and assigns floor requests to the two elevators based on a
// priority-based scheduling algorithm that considers elevator state, direction, and proximity.

`include "config.vh"

module scheduler (
  input clk,
  input reset,

  // --- External Inputs from Floors ---
  input [`NUM_FLOORS-1:0] up_calls,
  input [`NUM_FLOORS-1:0] down_calls,

  // --- Inputs from Elevator 1 ---
  input [`FLOOR_BITS-1:0] current_floor_e1,
  input [1:0] state_e1,
  input moving_up_e1,
  input moving_down_e1,
  input request_serviced_e1,
  input [`FLOOR_BITS-1:0] serviced_floor_e1,

  // --- Inputs from Elevator 2 ---
  input [`FLOOR_BITS-1:0] current_floor_e2,
  input [1:0] state_e2,
  input moving_up_e2,
  input moving_down_e2,
  input request_serviced_e2,
  input [`FLOOR_BITS-1:0] serviced_floor_e2,

  // --- Outputs to Elevators ---
  output reg [`NUM_FLOORS-1:0] requests_to_e1,
  output reg [`NUM_FLOORS-1:0] requests_to_e2
);

  // --- FSM State Parameters (matching elevator_fsm.v) ---
  parameter S_IDLE      = 2'd0;
  parameter S_MOVING_UP = 2'd2;
  parameter S_MOVING_DOWN = 2'd3;

  // --- Internal Registers for Pending Calls ---
  // These registers hold floor call requests until they are serviced.
  reg [`NUM_FLOORS-1:0] pending_up_calls;
  reg [`NUM_FLOORS-1:0] pending_down_calls;

  // --- Sequential Logic for Managing Call Requests ---
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      pending_up_calls <= 0;
      pending_down_calls <= 0;
    end else begin
      // Latch new external calls
      pending_up_calls <= pending_up_calls | up_calls;
      pending_down_calls <= pending_down_calls | down_calls;

      // Clear serviced calls for Elevator 1
      if (request_serviced_e1) begin
        pending_up_calls[serviced_floor_e1] <= 1'b0;
        pending_down_calls[serviced_floor_e1] <= 1'b0;
      end

      // Clear serviced calls for Elevator 2
      if (request_serviced_e2) begin
        pending_up_calls[serviced_floor_e2] <= 1'b0;
        pending_down_calls[serviced_floor_e2] <= 1'b0;
      end
    end
  end

  // --- Combinational Logic for Scheduling Algorithm ---
  always @(*) begin
    integer floor;
    integer cost_e1;
    integer cost_e2;

    // Default outputs
    requests_to_e1 = 0;
    requests_to_e2 = 0;

    // Iterate through each floor to check for pending requests
    for (floor = 0; floor < `NUM_FLOORS; floor = floor + 1) begin
      // --- UP CALL SCHEDULING ---
      if (pending_up_calls[floor]) begin
        // Calculate cost for each elevator to service this up call
        cost_e1 = calculate_cost(floor, current_floor_e1, state_e1, moving_up_e1, 1'b1);
        cost_e2 = calculate_cost(floor, current_floor_e2, state_e2, moving_up_e2, 1'b1);

        // Assign to the elevator with the lower cost
        if (cost_e1 <= cost_e2) begin
          requests_to_e1[floor] = 1'b1;
        end else begin
          requests_to_e2[floor] = 1'b1;
        end
      end

      // --- DOWN CALL SCHEDULING ---
      if (pending_down_calls[floor]) begin
        // Calculate cost for each elevator to service this down call
        cost_e1 = calculate_cost(floor, current_floor_e1, state_e1, moving_down_e1, 1'b0);
        cost_e2 = calculate_cost(floor, current_floor_e2, state_e2, moving_down_e2, 1'b0);

        // Assign to the elevator with the lower cost
        if (cost_e1 <= cost_e2) begin
          requests_to_e1[floor] = 1'b1;
        end else begin
          requests_to_e2[floor] = 1'b1;
        end
      end
    end
  end

  // --- Cost Calculation Function ---
  // This function calculates a 'cost' for an elevator to service a request.
  // A lower cost means a higher priority.
  function integer calculate_cost(input [`FLOOR_BITS-1:0] request_floor,
                                   input [`FLOOR_BITS-1:0] elev_floor,
                                   input [1:0] elev_state,
                                   input elev_direction, // 1 for up, 0 for down
                                   input request_is_up);
    integer distance;
    integer direction_mismatch;
    integer state_penalty;

    // 1. Distance Cost: The primary factor is the distance to the floor.
    if (elev_floor > request_floor) begin
      distance = elev_floor - request_floor;
    end else begin
      distance = request_floor - elev_floor;
    end

    // 2. Direction Mismatch Penalty: Penalize if the elevator is moving in the opposite direction.
    direction_mismatch = 0;
    if (elev_state == S_MOVING_UP && request_floor < elev_floor) begin
      direction_mismatch = 50; // Heavy penalty for moving away
    end
    if (elev_state == S_MOVING_DOWN && request_floor > elev_floor) begin
      direction_mismatch = 50; // Heavy penalty for moving away
    end

    // 3. State Penalty: IDLE elevators are the best candidates.
    state_penalty = 0;
    if (elev_state != S_IDLE) begin
      state_penalty = 10;
    end

    // Total Cost: A weighted sum of the factors.
    calculate_cost = (distance * 2) + direction_mismatch + state_penalty;
  endfunction

endmodule
