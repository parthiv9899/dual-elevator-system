// tb/scheduler_tb.v
// Comprehensive testbench for the scheduler module
// Tests priority algorithm, request arbitration, and request clearing

`timescale 1ns / 1ps
`include "config.vh"

module scheduler_tb;

    // -- Testbench signals --
    reg clk;
    reg reset;

    // External call requests
    reg [`NUM_FLOORS-1:0] up_calls;
    reg [`NUM_FLOORS-1:0] down_calls;

    // Elevator 1 inputs
    reg [`FLOOR_BITS-1:0] current_floor_e1;
    reg [1:0] state_e1;
    reg moving_up_e1;
    reg moving_down_e1;
    reg door_open_e1;
    reg request_serviced_e1;
    reg [`FLOOR_BITS-1:0] serviced_floor_e1;

    // Elevator 2 inputs
    reg [`FLOOR_BITS-1:0] current_floor_e2;
    reg [1:0] state_e2;
    reg moving_up_e2;
    reg moving_down_e2;
    reg door_open_e2;
    reg request_serviced_e2;
    reg [`FLOOR_BITS-1:0] serviced_floor_e2;

    // Scheduler outputs
    wire [`NUM_FLOORS-1:0] requests_to_e1;
    wire [`NUM_FLOORS-1:0] requests_to_e2;

    // Test control variables
    integer test_passed;
    integer test_failed;

    // State definitions
    parameter S_IDLE      = 2'd0;
    parameter S_DOOR_OPEN = 2'd1;
    parameter S_MOVING_UP = 2'd2;
    parameter S_MOVING_DOWN = 2'd3;

    // Instantiate the scheduler
    scheduler dut (
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
        .requests_to_e1(requests_to_e1),
        .requests_to_e2(requests_to_e2)
    );

    // Clock generation
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk; // 10ns period
    end

    // Assertion task
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

    // Helper task to simulate elevator reaching and servicing a floor
    task service_floor;
        input integer elevator_id; // 1 or 2
        input integer floor;
        input integer was_moving_up; // 1 if was moving up, 0 if down
        begin
            if (elevator_id == 1) begin
                current_floor_e1 = floor;
                moving_up_e1 = was_moving_up;
                moving_down_e1 = ~was_moving_up;
                #10;
                request_serviced_e1 = 1'b1;
                serviced_floor_e1 = floor;
                @(posedge clk);
                request_serviced_e1 = 1'b0;
                moving_up_e1 = 1'b0;
                moving_down_e1 = 1'b0;
            end else begin
                current_floor_e2 = floor;
                moving_up_e2 = was_moving_up;
                moving_down_e2 = ~was_moving_up;
                #10;
                request_serviced_e2 = 1'b1;
                serviced_floor_e2 = floor;
                @(posedge clk);
                request_serviced_e2 = 1'b0;
                moving_up_e2 = 1'b0;
                moving_down_e2 = 1'b0;
            end
        end
    endtask

    // Test sequence
    initial begin
        // Initialize
        test_passed = 0;
        test_failed = 0;

        $display("Time=%t: ========== Starting Scheduler Testbench ==========", $time);

        // Initialize all signals
        up_calls = {`NUM_FLOORS{1'b0}};
        down_calls = {`NUM_FLOORS{1'b0}};
        current_floor_e1 = 0;
        state_e1 = S_IDLE;
        moving_up_e1 = 1'b0;
        moving_down_e1 = 1'b0;
        door_open_e1 = 1'b0;
        request_serviced_e1 = 1'b0;
        serviced_floor_e1 = 0;
        current_floor_e2 = 0;
        state_e2 = S_IDLE;
        moving_up_e2 = 1'b0;
        moving_down_e2 = 1'b0;
        door_open_e2 = 1'b0;
        request_serviced_e2 = 1'b0;
        serviced_floor_e2 = 0;
        reset = 1'b1;
        #20;

        reset = 1'b0;
        $display("Time=%t: Reset released.", $time);
        #10;

        // TEST 1: Priority - Idle elevator gets request
        $display("Time=%t: ========== TEST 1: Idle Priority ==========", $time);
        up_calls[5] = 1'b1; // Call from floor 5
        current_floor_e1 = 0;
        state_e1 = S_IDLE;
        current_floor_e2 = 3;
        state_e2 = S_MOVING_UP;
        moving_up_e2 = 1'b1;
        #20;

        assert_condition(requests_to_e1[5] == 1'b1, "Idle E1 gets request over busy E2");
        assert_condition(requests_to_e2[5] == 1'b0, "Busy E2 doesn't get request");

        // TEST 2: Priority - Closest idle elevator
        $display("Time=%t: ========== TEST 2: Closest Idle Elevator ==========", $time);
        up_calls = {`NUM_FLOORS{1'b0}};
        down_calls = {`NUM_FLOORS{1'b0}};
        up_calls[4] = 1'b1;
        current_floor_e1 = 0;
        state_e1 = S_IDLE;
        current_floor_e2 = 6;
        state_e2 = S_IDLE;
        moving_up_e2 = 1'b0;
        #20;

        assert_condition(requests_to_e2[4] == 1'b1, "E2 (closer) gets request");
        assert_condition(requests_to_e1[4] == 1'b0, "E1 (farther) doesn't get request");

        // TEST 3: On-path pickup (elevator moving up, request above)
        $display("Time=%t: ========== TEST 3: On-Path Pickup ==========", $time);
        up_calls = {`NUM_FLOORS{1'b0}};
        down_calls = {`NUM_FLOORS{1'b0}};
        up_calls[6] = 1'b1;
        current_floor_e1 = 3;
        state_e1 = S_MOVING_UP;
        moving_up_e1 = 1'b1;
        current_floor_e2 = 7;
        state_e2 = S_IDLE;
        #20;

        assert_condition(requests_to_e1[6] == 1'b1, "E1 (on path) gets request");

        // TEST 4: Request clearing after service
        $display("Time=%t: ========== TEST 4: Request Clearing ==========", $time);
        up_calls = {`NUM_FLOORS{1'b0}};
        down_calls = {`NUM_FLOORS{1'b0}};
        up_calls[3] = 1'b1; // UP call at floor 3
        #20;

        // Simulate E1 servicing floor 3 while moving up
        service_floor(1, 3, 1); // E1 services floor 3, was moving up
        #20;

        assert_condition(requests_to_e1[3] == 1'b0, "UP request at floor 3 cleared after service");

        // TEST 5: Correct call type clearing (DOWN vs UP)
        $display("Time=%t: ========== TEST 5: Call Type Clearing ==========", $time);
        up_calls = {`NUM_FLOORS{1'b0}};
        down_calls = {`NUM_FLOORS{1'b0}};
        down_calls[5] = 1'b1; // DOWN call at floor 5
        up_calls[5] = 1'b1; // Also UP call at floor 5
        #20;

        // E2 services floor 5 while moving down - should clear DOWN call only
        service_floor(2, 5, 0); // E2 services floor 5, was moving down
        #20;

        assert_condition(requests_to_e2[5] == 1'b1, "UP request still pending after clearing DOWN");

        // Clear the UP call
        service_floor(2, 5, 1); // E2 services floor 5, now moving up
        #20;

        assert_condition(requests_to_e1[5] == 1'b0 && requests_to_e2[5] == 1'b0,
                        "Both calls cleared");

        // TEST 6: Multiple simultaneous requests
        $display("Time=%t: ========== TEST 6: Multiple Simultaneous Requests ==========", $time);
        up_calls = {`NUM_FLOORS{1'b0}};
        down_calls = {`NUM_FLOORS{1'b0}};
        up_calls[2] = 1'b1;
        up_calls[6] = 1'b1;
        current_floor_e1 = 0;
        state_e1 = S_IDLE;
        current_floor_e2 = 7;
        state_e2 = S_IDLE;
        #20;

        assert_condition((requests_to_e1[2] || requests_to_e2[2]) &&
                        (requests_to_e1[6] || requests_to_e2[6]),
                        "Both requests assigned to some elevator");
        assert_condition(!(requests_to_e1[2] && requests_to_e2[2]) &&
                        !(requests_to_e1[6] && requests_to_e2[6]),
                        "No request assigned to both elevators");

        // TEST 7: No double assignment
        $display("Time=%t: ========== TEST 7: No Double Assignment ==========", $time);
        up_calls = {`NUM_FLOORS{1'b0}};
        down_calls = {`NUM_FLOORS{1'b0}};
        down_calls[4] = 1'b1;
        current_floor_e1 = 4;
        state_e1 = S_IDLE;
        current_floor_e2 = 4;
        state_e2 = S_IDLE;
        #20;

        assert_condition(!(requests_to_e1[4] && requests_to_e2[4]),
                        "Request not assigned to both elevators");
        assert_condition(requests_to_e1[4] || requests_to_e2[4],
                        "Request assigned to at least one elevator");

        // Print test summary
        #50;
        $display("Time=%t: ========== Test Summary ==========", $time);
        $display("Tests Passed: %0d", test_passed);
        $display("Tests Failed: %0d", test_failed);
        if (test_failed == 0) begin
            $display("*** ALL TESTS PASSED ***");
        end else begin
            $display("*** SOME TESTS FAILED ***");
        end

        // Extended simulation time for better visualization (runs to ~40 seconds)
        $display("Time=%t: ========== Extended Simulation - Additional Activity ==========", $time);

        // Wave 1: Initial requests
        up_calls[2] = 1'b1;
        #200;
        up_calls[2] = 1'b0;
        down_calls[6] = 1'b1;
        #200;
        down_calls[6] = 1'b0;

        // Wave 2
        up_calls[4] = 1'b1;
        #200;
        up_calls[4] = 1'b0;
        down_calls[1] = 1'b1;
        #200;
        down_calls[1] = 1'b0;

        // Wave 3
        up_calls[7] = 1'b1;
        #200;
        up_calls[7] = 1'b0;
        down_calls[3] = 1'b1;
        #200;
        down_calls[3] = 1'b0;

        // Wave 4
        up_calls[5] = 1'b1;
        #200;
        up_calls[5] = 1'b0;
        down_calls[2] = 1'b1;
        #200;
        down_calls[2] = 1'b0;

        // Wave 5
        up_calls[1] = 1'b1;
        #200;
        up_calls[1] = 1'b0;
        down_calls[7] = 1'b1;
        #200;
        down_calls[7] = 1'b0;

        // Wave 6
        up_calls[3] = 1'b1;
        #200;
        up_calls[3] = 1'b0;
        down_calls[5] = 1'b1;
        #200;
        down_calls[5] = 1'b0;

        // Wave 7
        up_calls[6] = 1'b1;
        #200;
        up_calls[6] = 1'b0;
        down_calls[4] = 1'b1;
        #200;
        down_calls[4] = 1'b0;

        // Let simulation continue for remaining time to reach ~40 seconds
        #885;

        $display("Time=%t: Simulation finished.", $time);
        $finish;
    end

    // Monitoring and waveform dumping
    initial begin
        $monitor("Time=%t, E1[F=%0d,S=%0d], E2[F=%0d,S=%0d], UpCalls=%b, DownCalls=%b, ToE1=%b, ToE2=%b",
                 $time,
                 current_floor_e1, state_e1,
                 current_floor_e2, state_e2,
                 up_calls, down_calls,
                 requests_to_e1, requests_to_e2);

        $dumpfile("scheduler_tb.vcd");
        $dumpvars(0, scheduler_tb);
    end

endmodule
