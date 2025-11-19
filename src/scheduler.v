// src/scheduler.v
// Module for arbitrating and assigning floor requests to two elevators.
// This scheduler implements a simplified priority algorithm to assign
// external call requests to one of two elevators based on their current state,
// direction, and proximity.

`include "config.vh"

module scheduler (
    input clk,
    input reset,
    
    // External call requests from floors
    input [`NUM_FLOORS-1:0] up_calls,    // Up button pressed on a floor
    input [`NUM_FLOORS-1:0] down_calls,  // Down button pressed on a floor
    
    // Inputs from Elevator 1 (E1)
    input [`FLOOR_BITS-1:0] current_floor_e1,
    input [1:0] state_e1, // 0=IDLE, 1=DOOR_OPEN, 2=MOVING_UP, 3=MOVING_DOWN
    input moving_up_e1,
    input moving_down_e1,
    input door_open_e1,
    
    // Inputs from Elevator 2 (E2)
    input [`FLOOR_BITS-1:0] current_floor_e2,
    input [1:0] state_e2, // 0=IDLE, 1=DOOR_OPEN, 2=MOVING_UP, 3=MOVING_DOWN
    input moving_up_e2,
    input moving_down_e2,
    input door_open_e2,
    
    // Output: Requests assigned to each elevator
    output reg [`NUM_FLOORS-1:0] requests_to_e1,
    output reg [`NUM_FLOORS-1:0] requests_to_e2
);

    // Internal state for call requests (persists until serviced)
    reg [`NUM_FLOORS-1:0] pending_up_calls;
    reg [`NUM_FLOORS-1:0] pending_down_calls;

    // FSM states for scheduler decision making (using parameters from elevator_fsm indirectly)
    parameter S_IDLE      = 2'd0;
    parameter S_DOOR_OPEN = 2'd1;
    parameter S_MOVING_UP = 2'd2;
    parameter S_MOVING_DOWN = 2'd3;

    // Loop counter and decision flags, declared at module level for Verilog-2001 compatibility
    integer floor;
    reg assign_to_e1;
    reg assign_to_e2;
    reg e1_can_pickup;
    reg e2_can_pickup;
    reg [`FLOOR_BITS:0] dist_e1; // distance must be able to hold larger value than floor bits
    reg [`FLOOR_BITS:0] dist_e2;


    // Logic to update pending call requests
    // This block stores new requests and clears requests once serviced by an elevator.
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            pending_up_calls <= {`NUM_FLOORS{1'b0}};
            pending_down_calls <= {`NUM_FLOORS{1'b0}};
        end else begin
            // Store new call requests (buttons pressed on floors)
            pending_up_calls <= pending_up_calls | up_calls;
            pending_down_calls <= pending_down_calls | down_calls;

            // Clear call requests if an elevator services them
            // Elevator 1
            if (door_open_e1) begin // If E1's door is open at current_floor_e1
                // Determine if E1 picked up an UP or DOWN request
                if (state_e1 == S_MOVING_UP) begin // E1 was heading up
                    pending_up_calls[current_floor_e1] <= 1'b0;
                end else if (state_e1 == S_MOVING_DOWN) begin // E1 was heading down
                    pending_down_calls[current_floor_e1] <= 1'b0;
                end else begin // E1 was IDLE (state_e1 == S_IDLE) and opened door, assumes it serviced any call
                    pending_up_calls[current_floor_e1] <= 1'b0;
                    pending_down_calls[current_floor_e1] <= 1'b0;
                end
            end
            // Elevator 2 (same logic)
            if (door_open_e2) begin
                if (state_e2 == S_MOVING_UP) begin
                    pending_up_calls[current_floor_e2] <= 1'b0;
                end else if (state_e2 == S_MOVING_DOWN) begin
                    pending_down_calls[current_floor_e2] <= 1'b0;
                end else begin
                    pending_up_calls[current_floor_e2] <= 1'b0;
                    pending_down_calls[current_floor_e2] <= 1'b0;
                end
            end
        end
    end

    // Combinational logic for assigning requests to elevators
    always @(*) begin
        requests_to_e1 = {`NUM_FLOORS{1'b0}}; // Default to no requests for E1
        requests_to_e2 = {`NUM_FLOORS{1'b0}}; // Default to no requests for E2

        // Iterate through all floors to decide assignment for each pending request
        for (floor = 0; floor < `NUM_FLOORS; floor = floor + 1) begin
            // Only assign if there is a pending call request at this floor
            if (pending_up_calls[floor] || pending_down_calls[floor]) begin
                // Initialize flags for current floor's assignment
                assign_to_e1 = 1'b0;
                assign_to_e2 = 1'b0;

                // Calculate distances to current floor
                dist_e1 = (current_floor_e1 > floor) ? (current_floor_e1 - floor) : (floor - current_floor_e1);
                dist_e2 = (current_floor_e2 > floor) ? (current_floor_e2 - floor) : (floor - current_floor_e2);

                // --- Decision Logic for assigning a request at 'floor' ---
                // Priority: 1. Idle, 2. On-path, 3. Closest

                // 1. Check for IDLE elevators
                if (state_e1 == S_IDLE && state_e2 != S_IDLE) begin
                    assign_to_e1 = 1'b1;
                end else if (state_e2 == S_IDLE && state_e1 != S_IDLE) begin
                    assign_to_e2 = 1'b1;
                end else if (state_e1 == S_IDLE && state_e2 == S_IDLE) begin
                    // Both idle, assign to closest
                    if (dist_e1 <= dist_e2) begin
                        assign_to_e1 = 1'b1;
                    end else begin
                        assign_to_e2 = 1'b1;
                    end
                end 
                // 2. If no idle elevators, check for elevators MOVING IN THE SAME DIRECTION AND CAN PICK UP
                else begin 
                    // Initialize flags
                    e1_can_pickup = 1'b0;
                    e2_can_pickup = 1'b0;

                    // Check if E1 can pick up (moving up and request is above or at current floor, or moving down and request is below or at current floor)
                    if (pending_up_calls[floor] && moving_up_e1 && (current_floor_e1 <= floor)) e1_can_pickup = 1'b1;
                    if (pending_down_calls[floor] && moving_down_e1 && (current_floor_e1 >= floor)) e1_can_pickup = 1'b1;
                    
                    // Check if E2 can pick up
                    if (pending_up_calls[floor] && moving_up_e2 && (current_floor_e2 <= floor)) e2_can_pickup = 1'b1;
                    if (pending_down_calls[floor] && moving_down_e2 && (current_floor_e2 >= floor)) e2_can_pickup = 1'b1;

                    if (e1_can_pickup && !e2_can_pickup) begin
                        assign_to_e1 = 1'b1;
                    end else if (!e1_can_pickup && e2_can_pickup) begin
                        assign_to_e2 = 1'b1;
                    end else if (e1_can_pickup && e2_can_pickup) begin
                        // Both can pick up, assign to closest on path
                        if (dist_e1 <= dist_e2) begin
                            assign_to_e1 = 1'b1;
                        end else begin
                            assign_to_e2 = 1'b1;
                        end
                    end else begin
                        // 3. Neither idle nor on path, assign to CLOSEST (ignoring direction for now)
                        if (dist_e1 <= dist_e2) begin
                            assign_to_e1 = 1'b1;
                        end else begin
                            assign_to_e2 = 1'b1;
                        end
                    end
                end
                
                // Final assignment (a request can be assigned to both if logic dictates, but typically to one)
                // For simplicity, if both are flagged, the one with smaller ID (E1) gets it.
                if (assign_to_e1) requests_to_e1[floor] = 1'b1;
                else if (assign_to_e2) requests_to_e2[floor] = 1'b1;
            end
        end
    end

endmodule
