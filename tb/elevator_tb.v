// tb/elevator_tb.v
// This is the testbench for our FSM-based elevator module,
// adapted to Verilog-2001 style for maximum iverilog compatibility.

`timescale 1ns / 1ps
`include "config.vh"

module elevator_tb;

    // -- Testbench signals --
    // Use reg for signals driven from initial/always blocks
    reg clk;
    reg reset;
    reg emergency_stop;
    reg [`NUM_FLOORS-1:0] requests;

    // -- DUT Connections --
    // Use wire for signals driven by the DUT outputs
    wire [`FLOOR_BITS-1:0] current_floor;
    wire door_open;
    wire moving_up;
    wire moving_down;
    wire [1:0] elevator_state; // State is a 2-bit wire
    wire request_serviced;
    wire [`FLOOR_BITS-1:0] serviced_floor;

    // Test control variables
    integer test_passed;
    integer test_failed;

    // -- Instantiate the DUT (Design Under Test) --
    elevator_fsm dut (
        .clk(clk),
        .reset(reset),
        .emergency_stop(emergency_stop),
        .requests(requests),
        .current_floor(current_floor),
        .door_open(door_open),
        .moving_up(moving_up),
        .moving_down(moving_down),
        .state(elevator_state),
        .request_serviced(request_serviced),
        .serviced_floor(serviced_floor)
    );

    // -- Clock Generation --
    initial begin
        clk = 1'b0; // Use explicit 1'b0 for clarity
        forever #5 clk = ~clk; // 10ns period clock
    end
    
    // -- Task for making a request --
    // Using 'integer' for compatibility.
    task request_floor;
        input integer floor; // Task arguments are declared inside in Verilog-2001
        begin
            $display("Time=%t: >> Requesting floor %0d", $time, floor);
            requests[floor] = 1'b1; // Explicit 1'b1
        end
    endtask

    // -- Assertion task for checking conditions --
    task assert_condition;
        input condition;
        input [255:0] message;
        begin
            if (condition) begin
                test_passed = test_passed + 1;
                $display("Time=%t: [PASS] %0s", $time, message);
            end else begin
                test_failed = test_failed + 1;
                $display("Time=%t: [FAIL] %0s", $time, message);
            end
        end
    endtask

    // -- Test Sequence --
    initial begin
        // Initialize counters
        test_passed = 0;
        test_failed = 0;

        // 1. Initialize signals and assert reset
        $display("Time=%t: ========== Starting Elevator FSM Testbench ==========", $time);
        $display("Time=%t: Asserting reset.", $time);
        requests = {`NUM_FLOORS{1'b0}}; // Initialize all bits to 0
        reset = 1'b1;
        emergency_stop = 1'b0;
        #20;

        // 2. De-assert reset. Elevator should be in IDLE at floor 0.
        $display("Time=%t: De-asserting reset.", $time);
        reset = 1'b0;
        #10;

        assert_condition(elevator_state == 0, "Elevator starts in IDLE state");
        assert_condition(current_floor == 0, "Elevator starts at floor 0");

        // 3. Test: Request floor 4 and verify arrival
        $display("Time=%t: TEST 1: Moving up from floor 0 to floor 4", $time);
        request_floor(4);

        // Wait for elevator to reach floor 4 and open door
        @(posedge door_open);
        assert_condition(current_floor == 4, "Elevator reached floor 4");
        @(posedge clk); // Wait one cycle for request_serviced signal
        #1; // Allow signal to settle
        assert_condition(request_serviced == 1'b1, "Request serviced signal is high");
        assert_condition(serviced_floor == 4, "Serviced floor is 4");
        $display("Time=%t: << Elevator arrived at floor 4 and door is open.", $time);

        // Note: Requests are now cleared automatically by FSM signaling
        // The top-level module would handle the clearing
        @(negedge door_open);
        $display("Time=%t: << Door closed after servicing floor 4.", $time);
        #20;

        // 4. Test: Request floor 1 (moving down)
        $display("Time=%t: TEST 2: Moving down from floor 4 to floor 1", $time);
        // Clear previous request to simulate top-level clearing
        requests = {`NUM_FLOORS{1'b0}};
        request_floor(1);

        @(posedge door_open);
        assert_condition(current_floor == 1, "Elevator reached floor 1");
        @(posedge clk); // Wait one cycle for request_serviced signal
        #1; // Allow signal to settle
        assert_condition(request_serviced == 1'b1, "Request serviced signal is high");
        $display("Time=%t: << Elevator arrived at floor 1 and door is open.", $time);

        @(negedge door_open);
        $display("Time=%t: << Door closed after servicing floor 1.", $time);
        #20;

        // 5. Test: Emergency stop during movement
        $display("Time=%t: TEST 3: Emergency stop during movement", $time);
        requests = {`NUM_FLOORS{1'b0}};
        request_floor(7);

        // Wait for elevator to start moving
        @(posedge moving_up);
        $display("Time=%t: Elevator is moving up, asserting emergency stop", $time);
        #30; // Let it move a bit
        emergency_stop = 1'b1;
        #10;

        assert_condition(elevator_state == 0, "Elevator enters IDLE on emergency stop");
        assert_condition(moving_up == 1'b0, "Elevator stops moving up");
        assert_condition(moving_down == 1'b0, "Elevator stops moving down");
        $display("Time=%t: << Elevator stopped due to emergency", $time);

        // Resume from emergency
        #20;
        $display("Time=%t: Clearing emergency stop", $time);
        emergency_stop = 1'b0;
        #50; // Give time for elevator to resume
        $display("Time=%t: << Elevator resumed operation", $time);

        // 6. Test: Boundary conditions
        $display("Time=%t: TEST 4: Boundary conditions - floor 0 and floor 7", $time);
        requests = {`NUM_FLOORS{1'b0}};
        request_floor(0);
        @(posedge door_open);
        assert_condition(current_floor == 0, "Elevator reached floor 0 (bottom)");
        @(negedge door_open);
        #20;

        requests = {`NUM_FLOORS{1'b0}};
        request_floor(7);
        @(posedge door_open);
        assert_condition(current_floor == 7, "Elevator reached floor 7 (top)");
        assert_condition(moving_up == 1'b0, "Elevator stops at top floor");

        // 7. Print test summary
        #50;
        $display("Time=%t: ========== Test Summary ==========", $time);
        $display("Tests Passed: %0d", test_passed);
        $display("Tests Failed: %0d", test_failed);
        if (test_failed == 0) begin
            $display("*** ALL TESTS PASSED ***");
        end else begin
            $display("*** SOME TESTS FAILED ***");
        end
        $display("Time=%t: Simulation finished.", $time);
        $finish;
    end

    // -- Monitoring and Waveform Dumping --
    initial begin
        // Monitor prints a message whenever any of its arguments change.
        // States: 0=IDLE, 1=DOOR_OPEN, 2=MOVING_UP, 3=MOVING_DOWN
        $monitor("Time=%t, Floor=%0d, Requests=%b, DoorOpen=%b, Up=%b, Down=%b, State=%d, ReqSvc=%b, SvcFloor=%0d",
                 $time, current_floor, requests, door_open, moving_up, moving_down, elevator_state,
                 request_serviced, serviced_floor);

        $dumpfile("elevator_tb.vcd");
        $dumpvars(0, elevator_tb);
    end

endmodule
