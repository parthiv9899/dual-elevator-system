// src/elevator_fsm.v
// This module implements the Finite State Machine (FSM) for a single elevator.
// It controls the elevator's movement, door, and responds to floor requests.
// Using Verilog-2001 style for maximum compatibility with iverilog.

`include "config.vh"

module elevator_fsm (
    // == INPUTS ==
    input clk,                            // System clock
    input reset,                          // System reset
    input emergency_stop,                 // Emergency stop signal
    input [`NUM_FLOORS-1:0] requests,     // Bitmask of floor requests (1 for requested)

    // == OUTPUTS ==
    output [`FLOOR_BITS-1:0] current_floor, // The floor the elevator is currently at
    output door_open,                      // Signal to indicate if the door is open
    output moving_up,                        // Moving direction is up
    output moving_down,                      // Moving direction is down
    output [1:0] state,                      // The current state of the FSM (for debugging)
    output request_serviced,               // Pulses high when a floor request is serviced
    output [`FLOOR_BITS-1:0] serviced_floor // Which floor was just serviced
);

    // Output registers (used internally to drive output wires)
    reg [`FLOOR_BITS-1:0] current_floor_reg;
    reg door_open_reg;
    reg moving_up_reg;
    reg moving_down_reg;
    reg [1:0] state_reg; // State is a 2-bit register
    reg request_serviced_reg;
    reg [`FLOOR_BITS-1:0] serviced_floor_reg;

    // Assign internal registers to output ports
    assign current_floor = current_floor_reg;
    assign door_open = door_open_reg;
    assign moving_up = moving_up_reg;
    assign moving_down = moving_down_reg;
    assign state = state_reg;
    assign request_serviced = request_serviced_reg;
    assign serviced_floor = serviced_floor_reg;

    // -- State Definition --
    // We use parameters for states in Verilog-2001 style.
    parameter S_IDLE      = 2'd0;
    parameter S_DOOR_OPEN = 2'd1;
    parameter S_MOVING_UP = 2'd2;
    parameter S_MOVING_DOWN = 2'd3;

    // Internal next_state register
    reg [1:0] next_state;

    // Door timer - optimized to 3 bits (0-7 range, we need 0-5)
    reg [2:0] door_timer;

    parameter DOOR_OPEN_TIME = 5; // Door will stay open for 5 clock cycles

    // Internal registers for combinational logic flags and loop counter
    reg has_request_above;
    reg has_request_below;
    reg request_at_current_floor;
    integer i; // Loop counter declared at module level

    // --- Sequential Logic: State and Floor Register ---
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state_reg <= S_IDLE;
            current_floor_reg <= 'd0;
            door_timer <= 0;
            door_open_reg <= 1'b0;
            moving_up_reg <= 1'b0;
            moving_down_reg <= 1'b0;
            request_serviced_reg <= 1'b0;
            serviced_floor_reg <= 'd0;
        end else if (emergency_stop) begin // If emergency stop is active
            state_reg <= S_IDLE;          // Force to IDLE
            door_open_reg <= 1'b0;        // Ensure door is closed
            moving_up_reg <= 1'b0;        // Stop movement
            moving_down_reg <= 1'b0;      // Stop movement
            request_serviced_reg <= 1'b0; // Clear service signal
            // current_floor_reg remains unchanged
        end else begin // Normal operation
            state_reg <= next_state;

            // Default: request_serviced is a pulse (1 cycle high)
            request_serviced_reg <= 1'b0;

            // Update the floor only when in a moving state with boundary checks
            if (next_state == S_MOVING_UP && state_reg == S_MOVING_UP) begin
                // Only increment if not at top floor
                if (current_floor_reg < `NUM_FLOORS - 1) begin
                    current_floor_reg <= current_floor_reg + 1;
                end
            end else if (next_state == S_MOVING_DOWN && state_reg == S_MOVING_DOWN) begin
                // Only decrement if not at bottom floor
                if (current_floor_reg > 0) begin
                    current_floor_reg <= current_floor_reg - 1;
                end
            end

            // Handle the door timer and request servicing
            if (state_reg == S_DOOR_OPEN) begin
                door_timer <= door_timer - 1;
                // On first cycle of door opening, signal that request is serviced
                if (door_timer == DOOR_OPEN_TIME) begin
                    request_serviced_reg <= 1'b1;
                    serviced_floor_reg <= current_floor_reg;
                end
            end else if (next_state == S_DOOR_OPEN) begin
                door_timer <= DOOR_OPEN_TIME;
            end

            // Update direction outputs based on next state
            door_open_reg <= (next_state == S_DOOR_OPEN);
            moving_up_reg <= (next_state == S_MOVING_UP);
            moving_down_reg <= (next_state == S_MOVING_DOWN);
        end
    end

    // --- Combinational Logic: Next State Logic ---
    // Use always @(*) for combinational logic
    always @(*) begin
        // Default values for combinational variables
        next_state = state_reg; // Default next state is current state

        // Reset combinational flags before re-evaluation
        has_request_above = 1'b0;
        has_request_below = 1'b0;
        request_at_current_floor = 1'b0;

        for (i = 0; i < `NUM_FLOORS; i = i + 1) begin
            if (requests[i]) begin
                if (i > current_floor_reg) has_request_above = 1'b1;
                if (i < current_floor_reg) has_request_below = 1'b1;
            end
        end
        // If there's a request at the current floor
        if (requests[current_floor_reg]) request_at_current_floor = 1'b1;


        // FSM State Logic (only active if not in emergency stop)
        if (!emergency_stop) begin
            case (state_reg) // Use state_reg for case
                S_IDLE: begin
                    if (request_at_current_floor) begin
                        next_state = S_DOOR_OPEN;
                    end else if (has_request_above) begin
                        next_state = S_MOVING_UP;
                    end else if (has_request_below) begin
                        next_state = S_MOVING_DOWN;
                    end
                end

                S_DOOR_OPEN: begin
                    // Door open signal is handled in sequential block
                    if (door_timer == 0) begin
                        if (has_request_above) begin
                            next_state = S_MOVING_UP;
                        end else if (has_request_below) begin
                            next_state = S_MOVING_DOWN;
                        end else begin
                            next_state = S_IDLE;
                        end
                    end
                end

                S_MOVING_UP: begin
                    // Moving up signal is handled in sequential block
                    if (request_at_current_floor) begin
                        next_state = S_DOOR_OPEN;
                    end else if (!has_request_above && has_request_below) begin
                        next_state = S_MOVING_DOWN;
                    end else if (!has_request_above && !has_request_below) begin
                        next_state = S_IDLE;
                    end else begin
                        next_state = S_MOVING_UP;
                    end
                end

                S_MOVING_DOWN: begin
                    // Moving down signal is handled in sequential block
                    if (request_at_current_floor) begin
                        next_state = S_DOOR_OPEN;
                    end else if (!has_request_below && has_request_above) begin
                        next_state = S_MOVING_UP;
                    end else if (!has_request_above && !has_request_below) begin
                        next_state = S_IDLE;
                    end else begin
                        next_state = S_MOVING_DOWN;
                    end
                end

                default: begin
                    next_state = S_IDLE;
                end
            endcase
        end
    end

endmodule
