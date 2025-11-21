// src/dual_elevator_top.v
// Top-level module for the dual elevator system.
// This module integrates two independent elevator FSMs with a central scheduler
// to manage floor calls and elevator assignments.

`include "config.vh"

module dual_elevator_top (
  input clk,
  input reset,
  input emergency_stop, // Global emergency stop signal

  // --- External Inputs from Floors ---
  input [`NUM_FLOORS-1:0] up_calls,
  input [`NUM_FLOORS-1:0] down_calls,

  // --- Internal Inputs from Elevators ---
  input [`NUM_FLOORS-1:0] destination_e1, // Destination requests from inside elevator 1
  input [`NUM_FLOORS-1:0] destination_e2, // Destination requests from inside elevator 2

  // --- Outputs for Elevator 1 ---
  output wire [`FLOOR_BITS-1:0] current_floor_e1,
  output wire door_open_e1,
  output wire moving_up_e1,
  output wire moving_down_e1,
  output wire [1:0] state_e1,

  // --- Outputs for Elevator 2 ---
  output wire [`FLOOR_BITS-1:0] current_floor_e2,
  output wire door_open_e2,
  output wire moving_up_e2,
  output wire moving_down_e2,
  output wire [1:0] state_e2,

  // --- Debug Outputs ---
  output wire [`NUM_FLOORS-1:0] debug_pending_dest_e1,
  output wire [`NUM_FLOORS-1:0] debug_pending_dest_e2
);

  // --- Internal Wires and Registers ---

  // Wires connecting the scheduler to each elevator
  wire [`NUM_FLOORS-1:0] scheduler_requests_e1;
  wire [`NUM_FLOORS-1:0] scheduler_requests_e2;

  // Feedback signals from elevators indicating a request has been serviced
  wire request_serviced_e1;
  wire [`FLOOR_BITS-1:0] serviced_floor_e1;
  wire request_serviced_e2;
  wire [`FLOOR_BITS-1:0] serviced_floor_e2;

  // Registers to hold persistent destination requests made from inside each elevator
  reg [`NUM_FLOORS-1:0] pending_dest_e1;
  reg [`NUM_FLOORS-1:0] pending_dest_e2;

  // Combined requests for each elevator (scheduler + internal destinations)
  wire [`NUM_FLOORS-1:0] combined_requests_e1;
  wire [`NUM_FLOORS-1:0] combined_requests_e2;

  // --- Assignments ---

  // Connect debug outputs to internal registers
  assign debug_pending_dest_e1 = pending_dest_e1;
  assign debug_pending_dest_e2 = pending_dest_e2;

  // Combine requests from the scheduler with internal destination requests
  assign combined_requests_e1 = scheduler_requests_e1 | pending_dest_e1;
  assign combined_requests_e2 = scheduler_requests_e2 | pending_dest_e2;

  // --- Sequential Logic for Destination Requests ---

  // This block manages the internal destination buttons for each elevator.
  // It latches new requests and clears them only when the elevator reports servicing that floor.
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      pending_dest_e1 <= {`NUM_FLOORS{1'b0}};
      pending_dest_e2 <= {`NUM_FLOORS{1'b0}};
    end else begin
      // Latch new destination requests
      pending_dest_e1 <= pending_dest_e1 | destination_e1;
      pending_dest_e2 <= pending_dest_e2 | destination_e2;

      // Clear the request for a floor when the elevator services it
      if (request_serviced_e1) begin
        pending_dest_e1[serviced_floor_e1] <= 1'b0;
      end
      if (request_serviced_e2) begin
        pending_dest_e2[serviced_floor_e2] <= 1'b0;
      end
    end
  end

  // --- Module Instantiations ---

  // Central Scheduler: Assigns floor calls to the most suitable elevator
  scheduler u_scheduler (
    .clk(clk),
    .reset(reset),
    .up_calls(up_calls),
    .down_calls(down_calls),
    .current_floor_e1(current_floor_e1),
    .state_e1(state_e1),
    .current_floor_e2(current_floor_e2),
    .state_e2(state_e2),
    .requests_to_e1(scheduler_requests_e1),
    .requests_to_e2(scheduler_requests_e2)
  );

  // Elevator 1: Instance of the main elevator FSM
  elevator_fsm u_elevator_1 (
    .clk(clk),
    .reset(reset),
    .emergency_stop(emergency_stop),
    .requests(combined_requests_e1),
    .current_floor(current_floor_e1),
    .door_open(door_open_e1),
    .moving_up(moving_up_e1),
    .moving_down(moving_down_e1),
    .state(state_e1),
    .request_serviced(request_serviced_e1),
    .serviced_floor(serviced_floor_e1)
  );

  // Elevator 2: Second instance of the elevator FSM
  elevator_fsm u_elevator_2 (
    .clk(clk),
    .reset(reset),
    .emergency_stop(emergency_stop),
    .requests(combined_requests_e2),
    .current_floor(current_floor_e2),
    .door_open(door_open_e2),
    .moving_up(moving_up_e2),
    .moving_down(moving_down_e2),
    .state(state_e2),
    .request_serviced(request_serviced_e2),
    .serviced_floor(serviced_floor_e2)
  );

endmodule
