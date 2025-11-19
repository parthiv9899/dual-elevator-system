// tb/dual_elevator_tb.v
// Testbench for the dual elevator system, including emergency stop functionality.

`timescale 1ns / 1ps
`include "config.vh"

module dual_elevator_tb;

    // -- Testbench signals --
    reg clk;
    reg reset;
    reg emergency_stop; // New: Emergency stop signal
    reg [`NUM_FLOORS-1:0] up_calls;
    reg [`NUM_FLOORS-1:0] down_calls;
    reg [`NUM_FLOORS-1:0] destination_e1;
    reg [`NUM_FLOORS-1:0] destination_e2;

    // -- DUT Connections (outputs from dual_elevator_top) --
    wire [`FLOOR_BITS-1:0] current_floor_e1;
    wire door_open_e1;
    wire moving_up_e1;
    wire moving_down_e1;
    wire [1:0] state_e1;

    wire [`FLOOR_BITS-1:0] current_floor_e2;
    wire door_open_e2;
    wire moving_up_e2;
    wire moving_down_e2;
    wire [1:0] state_e2;

    // Instantiate the Dual Elevator Top Module
    dual_elevator_top dut (
        .clk(clk),
        .reset(reset),
        .emergency_stop(emergency_stop), // New: Connect emergency_stop
        .up_calls(up_calls),
        .down_calls(down_calls),
        .destination_e1(destination_e1),
        .destination_e2(destination_e2),
        .current_floor_e1(current_floor_e1),
        .door_open_e1(door_open_e1),
        .moving_up_e1(moving_up_e1),
        .moving_down_e1(moving_down_e1),
        .state_e1(state_e1),
        .current_floor_e2(current_floor_e2),
        .door_open_e2(door_open_e2),
        .moving_up_e2(moving_up_e2),
        .moving_down_e2(moving_down_e2),
        .state_e2(state_e2)
    );

    // -- Clock Generation --
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk; // 10ns period
    end

    // Helper task to make an external call request (pulsed)
    task make_call;
        input integer floor;
        input reg direction_up; // 1 for up, 0 for down
        begin
            $display("Time=%t: >> EXTERNAL CALL: Floor %0d, Direction %s", $time, floor, direction_up ? "UP" : "DOWN");
            if (direction_up) up_calls[floor] = 1'b1;
            else down_calls[floor] = 1'b1;
            #10; // Pulse the request for one clock cycle
            up_calls[floor] = 1'b0;
            down_calls[floor] = 1'b0;
        end
    endtask

    // Helper task to make an internal destination request (pulsed)
    task make_destination_request;
        input integer elevator_id; // 1 for E1, 2 for E2
        input integer floor;
        begin
            $display("Time=%t: >> DESTINATION REQUEST (E%0d): Floor %0d", $time, elevator_id, floor);
            if (elevator_id == 1) begin
                destination_e1[floor] = 1'b1;
                #10;
                destination_e1[floor] = 1'b0;
            end else begin
                destination_e2[floor] = 1'b1;
                #10;
                destination_e2[floor] = 1'b0;
            end
        end
    endtask


    // -- Test Sequence --
    initial begin
        $display("Time=%t: Starting dual elevator simulation.", $time);
        // Initialize all signals
        up_calls = {`NUM_FLOORS{1'b0}};
        down_calls = {`NUM_FLOORS{1'b0}};
        destination_e1 = {`NUM_FLOORS{1'b0}};
        destination_e2 = {`NUM_FLOORS{1'b0}};
        reset = 1'b1;
        emergency_stop = 1'b0; // Initialize emergency stop to inactive
        #20;

        reset = 1'b0; // Release reset
        $display("Time=%t: Reset released.", $time);
        #10;

        // Scenario 1: Basic requests, one elevator handles
        make_call(4, 1); // Call UP from floor 4
        #100; // Wait for E1 to handle it (assuming E1 is closer)
        make_destination_request(1, 2); // E1 passenger requests floor 2
        #100;

        // Scenario 2: Two requests, two elevators
        make_call(7, 0); // Call DOWN from floor 7
        make_call(1, 1); // Call UP from floor 1 (E2 should get this, if E1 is going to 2)
        #200;

        // Scenario 3: Test Emergency Stop
        $display("Time=%t: ASSERTING EMERGENCY STOP!", $time);
        emergency_stop = 1'b1; // Activate emergency stop
        #50;
        $display("Time=%t: DE-ASSERTING EMERGENCY STOP!", $time);
        emergency_stop = 1'b0; // Deactivate emergency stop
        #100;

        $display("Time=%t: Simulation finished.", $time);
        $finish;
    end

    // -- Monitoring and Waveform Dumping --
    initial begin
        // States: 0=IDLE, 1=DOOR_OPEN, 2=MOVING_UP, 3=MOVING_DOWN
        $monitor("Time=%t, EmergencyStop=%b, E1_Floor=%0d, E1_State=%d, E1_Door=%b, E2_Floor=%0d, E2_State=%d, E2_Door=%b, UpCalls=%b, DownCalls=%b",
                 $time, emergency_stop, current_floor_e1, state_e1, door_open_e1, current_floor_e2, state_e2, door_open_e2, up_calls, down_calls);
                 
        $dumpfile("tb/dual_elevator_tb.vcd");
        $dumpvars(0, dual_elevator_tb);
    end

endmodule
