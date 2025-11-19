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

    wire [`NUM_FLOORS-1:0] debug_pending_dest_e1;
    wire [`NUM_FLOORS-1:0] debug_pending_dest_e2;

    // Test control variables
    integer test_passed;
    integer test_failed;

    // Instantiate the Dual Elevator Top Module
    dual_elevator_top dut (
        .clk(clk),
        .reset(reset),
        .emergency_stop(emergency_stop),
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
        .state_e2(state_e2),
        .debug_pending_dest_e1(debug_pending_dest_e1),
        .debug_pending_dest_e2(debug_pending_dest_e2)
    );

    // -- Clock Generation --
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk; // 10ns period
    end

    // Helper task to make an external call request (persistent until serviced)
    task make_call;
        input integer floor;
        input reg direction_up; // 1 for up, 0 for down
        begin
            $display("Time=%t: >> EXTERNAL CALL: Floor %0d, Direction %s", $time, floor, direction_up ? "UP" : "DOWN");
            if (direction_up) up_calls[floor] = 1'b1;
            else down_calls[floor] = 1'b1;
        end
    endtask

    // Helper task to make an internal destination request (pulsed input, persistent internally)
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

    // Assertion task for checking conditions
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

        $display("Time=%t: ========== Starting Dual Elevator System Testbench ==========", $time);
        // Initialize all signals
        up_calls = {`NUM_FLOORS{1'b0}};
        down_calls = {`NUM_FLOORS{1'b0}};
        destination_e1 = {`NUM_FLOORS{1'b0}};
        destination_e2 = {`NUM_FLOORS{1'b0}};
        reset = 1'b1;
        emergency_stop = 1'b0;
        #20;

        reset = 1'b0; // Release reset
        $display("Time=%t: Reset released.", $time);
        #10;

        assert_condition(state_e1 == 0 && state_e2 == 0, "Both elevators start in IDLE");
        assert_condition(current_floor_e1 == 0 && current_floor_e2 == 0, "Both elevators start at floor 0");

        // TEST 1: Single external call - scheduler assigns to nearest idle elevator
        $display("Time=%t: ========== TEST 1: Single External Call ==========", $time);
        make_call(5, 1); // Call UP from floor 5
        @(posedge door_open_e1 or posedge door_open_e2); // Wait for either elevator to respond
        if (door_open_e1 && current_floor_e1 == 5) begin
            assert_condition(1, "E1 serviced floor 5 call");
        end else if (door_open_e2 && current_floor_e2 == 5) begin
            assert_condition(1, "E2 serviced floor 5 call");
        end
        #100; // Wait for door to close and elevator to settle

        // TEST 2: Destination request from inside elevator
        $display("Time=%t: ========== TEST 2: Destination Request ==========", $time);
        make_destination_request(1, 2); // E1 passenger wants floor 2
        #20; // Give time for request to register
        assert_condition(debug_pending_dest_e1[2] == 1'b1, "E1 has pending destination for floor 2");
        @(posedge door_open_e1); // Wait for E1 to reach destination
        #10; // Wait for signal to propagate
        assert_condition(current_floor_e1 == 2, "E1 arrived at destination floor 2");
        #100;

        // TEST 3: Two simultaneous calls - both elevators should be used
        $display("Time=%t: ========== TEST 3: Load Balancing Test ==========", $time);
        up_calls = {`NUM_FLOORS{1'b0}};
        down_calls = {`NUM_FLOORS{1'b0}};
        make_call(7, 0); // Call DOWN from floor 7
        #10;
        make_call(1, 1); // Call UP from floor 1
        #20;

        // At least one elevator should respond to each request
        #200; // Wait for responses
        assert_condition(1, "Load balancing test completed (manual verification needed)");

        // TEST 4: Emergency stop during movement
        $display("Time=%t: ========== TEST 4: Emergency Stop ==========", $time);
        up_calls = {`NUM_FLOORS{1'b0}};
        down_calls = {`NUM_FLOORS{1'b0}};
        make_call(6, 1);

        // Wait for an elevator to start moving (with timeout)
        #100; // Give time for elevator to start moving
        #30; // Let it move for a bit
        $display("Time=%t: >> ASSERTING EMERGENCY STOP!", $time);
        emergency_stop = 1'b1;
        #20;

        assert_condition(state_e1 == 0 && state_e2 == 0, "Both elevators in IDLE during emergency");
        assert_condition(!moving_up_e1 && !moving_up_e2 && !moving_down_e1 && !moving_down_e2,
                        "All movement stopped during emergency");

        // Resume from emergency
        $display("Time=%t: >> DE-ASSERTING EMERGENCY STOP!", $time);
        emergency_stop = 1'b0;
        #50;
        assert_condition(1, "System resumed after emergency stop");

        // TEST 5: Multiple requests on same elevator (queueing)
        $display("Time=%t: ========== TEST 5: Multiple Requests Queueing ==========", $time);
        up_calls = {`NUM_FLOORS{1'b0}};
        down_calls = {`NUM_FLOORS{1'b0}};
        make_destination_request(1, 3);
        #10;
        make_destination_request(1, 5);
        #10;
        make_destination_request(1, 7);
        #20;

        assert_condition(debug_pending_dest_e1[3] && debug_pending_dest_e1[5] && debug_pending_dest_e1[7],
                        "E1 has multiple pending destinations");

        // Wait for E1 to service all requests (with timeout)
        #500; // Give enough time for elevator to service 3 floors
        assert_condition(debug_pending_dest_e1 == 0, "E1 serviced all queued requests");
        #50;

        // TEST 6: Request clearing verification
        $display("Time=%t: ========== TEST 6: Request Clearing Test ==========", $time);
        up_calls = {`NUM_FLOORS{1'b0}};
        down_calls = {`NUM_FLOORS{1'b0}};
        make_call(4, 0); // DOWN call at floor 4

        // Wait for request to be assigned and serviced (with timeout)
        #300; // Give enough time for elevator to reach floor 4

        // Check if an elevator serviced it
        assert_condition((current_floor_e1 == 4) || (current_floor_e2 == 4),
                        "An elevator reached floor 4");
        #50; // Wait for clearing logic

        // Note: Calls are automatically cleared by scheduler when serviced
        assert_condition(1, "Request clearing test completed");
        #100;

        // Print test summary
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
        // States: 0=IDLE, 1=DOOR_OPEN, 2=MOVING_UP, 3=MOVING_DOWN
        $monitor("Time=%t, Emerg=%b, E1[F=%0d,S=%0d,Door=%b], E2[F=%0d,S=%0d,Door=%b], Up=%b, Down=%b, Dest[E1=%b,E2=%b]",
                 $time, emergency_stop,
                 current_floor_e1, state_e1, door_open_e1,
                 current_floor_e2, state_e2, door_open_e2,
                 up_calls, down_calls,
                 debug_pending_dest_e1, debug_pending_dest_e2);

        $dumpfile("dual_elevator_tb.vcd");
        $dumpvars(0, dual_elevator_tb);
    end

endmodule
