// src/elevator_fsm.v
// This module implements the Finite State Machine (FSM) for a single elevator.
// It controls the elevator's movement, door, and responds to floor requests.

`include "config.vh"

module elevator_fsm (
  // --- INPUTS ---
  input clk,
  input reset,
  input emergency_stop,
  input [`NUM_FLOORS-1:0] requests, // Bitmask of floor requests

  // --- OUTPUTS ---
  output [`FLOOR_BITS-1:0] current_floor,
  output door_open,
  output moving_up,
  output moving_down,
  output [1:0] state, // Current state of the FSM
  output request_serviced, // Pulses high when a floor is serviced
  output [`FLOOR_BITS-1:0] serviced_floor
);

  // --- FSM State Definition ---
  parameter S_IDLE      = 2'd0; // Elevator is stationary, door closed
  parameter S_DOOR_OPEN = 2'd1; // Elevator is at a floor with door open
  parameter S_MOVING_UP = 2'd2; // Elevator is moving upwards
  parameter S_MOVING_DOWN = 2'd3; // Elevator is moving downwards

  // --- Internal Registers ---
  reg [`FLOOR_BITS-1:0] current_floor_reg;
  reg door_open_reg;
  reg moving_up_reg;
  reg moving_down_reg;
  reg [1:0] state_reg;
  reg request_serviced_reg;
  reg [`FLOOR_BITS-1:0] serviced_floor_reg;
  reg [1:0] next_state;
  reg [`DOOR_TIMER_CYCLES-1:0] door_timer; // Timer for how long the door stays open
  reg [`MOVE_TIMER_CYCLES-1:0] move_timer; // Timer for moving between floors

  // --- Assignments to Outputs ---
  assign current_floor = current_floor_reg;
  assign door_open = door_open_reg;
  assign moving_up = moving_up_reg;
  assign moving_down = moving_down_reg;
  assign state = state_reg;
  assign request_serviced = request_serviced_reg;
  assign serviced_floor = serviced_floor_reg;

  // --- Combinational Logic for Request Analysis ---
  wire has_request_above;
  wire has_request_below;
  wire request_at_current_floor;

  // Check if there is any request above the current floor
  assign has_request_above = |(requests[`NUM_FLOORS-1:current_floor_reg+1]);
  // Check if there is any request below the current floor
  assign has_request_below = |(requests[current_floor_reg-1:0]);
  // Check if there is a request at the current floor
  assign request_at_current_floor = requests[current_floor_reg];

  // --- Sequential Logic Block (State, Floor, and Timers) ---
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      // Reset all state variables to default values
      state_reg <= S_IDLE;
      current_floor_reg <= 0;
      door_timer <= 0;
      move_timer <= 0;
      door_open_reg <= 1'b0;
      moving_up_reg <= 1'b0;
      moving_down_reg <= 1'b0;
      request_serviced_reg <= 1'b0;
      serviced_floor_reg <= 0;
    end else if (emergency_stop) begin
      // In an emergency, stop all movement and close doors
      state_reg <= S_IDLE;
      door_open_reg <= 1'b0;
      moving_up_reg <= 1'b0;
      moving_down_reg <= 1'b0;
      request_serviced_reg <= 1'b0;
      // Floor position is maintained
    end else begin
      // Default behavior: serviced pulse is one cycle
      request_serviced_reg <= 1'b0;

      // Update state
      state_reg <= next_state;

      // Handle timers and floor movement
      case(state_reg)
        S_DOOR_OPEN: begin
          if (door_timer > 0) begin
            door_timer <= door_timer - 1;
          end
        end
        S_MOVING_UP: begin
          if (move_timer > 0) begin
            move_timer <= move_timer - 1;
          end else if (current_floor_reg < `NUM_FLOORS - 1) begin
            current_floor_reg <= current_floor_reg + 1;
            move_timer <= `MOVE_TIMER_CYCLES - 1;
          end
        end
        S_MOVING_DOWN: begin
          if (move_timer > 0) begin
            move_timer <= move_timer - 1;
          end else if (current_floor_reg > 0) begin
            current_floor_reg <= current_floor_reg - 1;
            move_timer <= `MOVE_TIMER_CYCLES - 1;
          end
        end
      endcase

      // When entering DOOR_OPEN state, set the timer and issue service pulse
      if (next_state == S_DOOR_OPEN && state_reg != S_DOOR_OPEN) begin
        door_timer <= `DOOR_TIMER_CYCLES - 1;
        request_serviced_reg <= 1'b1;
        serviced_floor_reg <= current_floor_reg;
      end

      // Update output signals based on the *next* state for faster response
      door_open_reg <= (next_state == S_DOOR_OPEN);
      moving_up_reg <= (next_state == S_MOVING_UP);
      moving_down_reg <= (next_state == S_MOVING_DOWN);
    end
  end

  // --- Combinational Logic for Next State Determination ---
  always @(*) begin
    // Default to staying in the current state
    next_state = state_reg;

    // FSM State Transition Logic
    case (state_reg)
      S_IDLE: begin
        // If there's a request at the current floor, open the door.
        if (request_at_current_floor) begin
          next_state = S_DOOR_OPEN;
        // If there are requests above, start moving up.
        end else if (has_request_above) begin
          next_state = S_MOVING_UP;
        // If there are requests below, start moving down.
        end else if (has_request_below) begin
          next_state = S_MOVING_DOWN;
        end
      end

      S_DOOR_OPEN: begin
        // When the door timer finishes, decide where to go next.
        if (door_timer == 0) begin
          if (moving_up_reg && has_request_above) begin
            next_state = S_MOVING_UP;
          end else if (moving_down_reg && has_request_below) begin
            next_state = S_MOVING_DOWN;
          end else if (has_request_above) begin
            next_state = S_MOVING_UP;
          end else if (has_request_below) begin
            next_state = S_MOVING_DOWN;
          end else begin
            next_state = S_IDLE;
          end
        end
      end

      S_MOVING_UP: begin
        // If we arrive at a requested floor, open the door.
        if (request_at_current_floor) begin
          next_state = S_DOOR_OPEN;
        // If no more requests above, but there are requests below, change direction.
        end else if (!has_request_above && has_request_below) begin
          next_state = S_MOVING_DOWN;
        // If all requests are serviced, go to idle.
        end else if (!has_request_above && !has_request_below) begin
          next_state = S_IDLE;
        end
      end

      S_MOVING_DOWN: begin
        // If we arrive at a requested floor, open the door.
        if (request_at_current_floor) begin
          next_state = S_DOOR_OPEN;
        // If no more requests below, but there are requests above, change direction.
        end else if (!has_request_below && has_request_above) begin
          next_state = S_MOVING_UP;
        // If all requests are serviced, go to idle.
        end else if (!has_request_above && !has_request_below) begin
          next_state = S_IDLE;
        end
      end

      default: begin
        next_state = S_IDLE;
      end
    endcase
  end

endmodule
