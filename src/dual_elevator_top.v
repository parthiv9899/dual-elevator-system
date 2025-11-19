// src/dual_elevator_top.v
// Top-level module for the dual elevator system.
// Connects two elevator FSMs with a central scheduler.

`include "config.vh"

module dual_elevator_top (
    input clk,
    input reset,
    input emergency_stop, // Emergency stop signal

    // External call buttons from floors
    input [`NUM_FLOORS-1:0] up_calls,    // Up button pressed on a floor
    input [`NUM_FLOORS-1:0] down_calls,  // Down button pressed on a floor

    // Passenger destination requests (inside elevator 1) - pulsed inputs
    input [`NUM_FLOORS-1:0] destination_e1,
    // Passenger destination requests (inside elevator 2) - pulsed inputs
    input [`NUM_FLOORS-1:0] destination_e2,

    // Outputs for Elevator 1
    output wire [`FLOOR_BITS-1:0] current_floor_e1,
    output wire door_open_e1,
    output wire moving_up_e1,
    output wire moving_down_e1,
    output wire [1:0] state_e1,

    // Outputs for Elevator 2
    output wire [`FLOOR_BITS-1:0] current_floor_e2,
    output wire door_open_e2,
    output wire moving_up_e2,
    output wire moving_down_e2,
    output wire [1:0] state_e2,

    // Debug outputs
    output wire [`NUM_FLOORS-1:0] debug_pending_dest_e1, // Pending destination requests for E1
    output wire [`NUM_FLOORS-1:0] debug_pending_dest_e2  // Pending destination requests for E2
);

    // Wires to connect scheduler outputs to elevator inputs
    wire [`NUM_FLOORS-1:0] scheduler_requests_e1;
    wire [`NUM_FLOORS-1:0] scheduler_requests_e2;

    // Internal wires for request servicing signals from elevators
    wire request_serviced_e1;
    wire [`FLOOR_BITS-1:0] serviced_floor_e1;
    wire request_serviced_e2;
    wire [`FLOOR_BITS-1:0] serviced_floor_e2;

    // Internal registers for persistent destination requests
    reg [`NUM_FLOORS-1:0] pending_dest_e1;
    reg [`NUM_FLOORS-1:0] pending_dest_e2;

    // Internal wires for combined requests (scheduler output + destination requests)
    wire [`NUM_FLOORS-1:0] combined_requests_e1;
    wire [`NUM_FLOORS-1:0] combined_requests_e2;

    // Connect debug outputs
    assign debug_pending_dest_e1 = pending_dest_e1;
    assign debug_pending_dest_e2 = pending_dest_e2;

    // Sequential logic to manage destination requests
    // Destination requests persist until serviced by the elevator
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            pending_dest_e1 <= {`NUM_FLOORS{1'b0}};
            pending_dest_e2 <= {`NUM_FLOORS{1'b0}};
        end else begin
            // Add new destination requests (OR with existing)
            pending_dest_e1 <= pending_dest_e1 | destination_e1;
            pending_dest_e2 <= pending_dest_e2 | destination_e2;

            // Clear destination requests when elevator services the floor
            if (request_serviced_e1) begin
                pending_dest_e1[serviced_floor_e1] <= 1'b0;
            end
            if (request_serviced_e2) begin
                pending_dest_e2[serviced_floor_e2] <= 1'b0;
            end
        end
    end

    // Instantiate the Scheduler
    // The scheduler does NOT receive the emergency_stop signal directly,
    // as it should continue to track requests. The elevators themselves
    // handle the stop/resume logic.
    scheduler u_scheduler (
        .clk(clk),
        .reset(reset),
        .up_calls(up_calls),
        .down_calls(down_calls),
        .current_floor_e1(current_floor_e1),
        .state_e1(state_e1),
        .moving_up_e1(moving_up_e1),
        .moving_down_e1(moving_down_e1),
        .door_open_e1(door_open_e1),
        .request_serviced_e1(request_serviced_e1),
        .serviced_floor_e1(serviced_floor_e1),
        .current_floor_e2(current_floor_e2),
        .state_e2(state_e2),
        .moving_up_e2(moving_up_e2),
        .moving_down_e2(moving_down_e2),
        .door_open_e2(door_open_e2),
        .request_serviced_e2(request_serviced_e2),
        .serviced_floor_e2(serviced_floor_e2),
        .requests_to_e1(scheduler_requests_e1),
        .requests_to_e2(scheduler_requests_e2)
    );

    // Combine scheduler-assigned requests with in-elevator destination requests
    // The OR operation means if either the scheduler or the destination button requests a floor, it's a valid request.
    assign combined_requests_e1 = scheduler_requests_e1 | pending_dest_e1;
    assign combined_requests_e2 = scheduler_requests_e2 | pending_dest_e2;

    // Instantiate Elevator 1
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

    // Instantiate Elevator 2
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
