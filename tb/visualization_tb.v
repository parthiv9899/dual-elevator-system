// tb/visualization_tb.v
// Testbench specifically designed for live animation visualization
// Generates realistic elevator traffic over 40 seconds

`timescale 1ns / 1ps
`include "config.vh"

module visualization_tb;

    reg clk;
    reg reset;
    reg emergency_stop;

    // External call buttons
    reg [`NUM_FLOORS-1:0] up_calls;
    reg [`NUM_FLOORS-1:0] down_calls;

    // Destination buttons
    reg [`NUM_FLOORS-1:0] destination_e1;
    reg [`NUM_FLOORS-1:0] destination_e2;

    // Outputs
    wire [`FLOOR_BITS-1:0] current_floor_e1;
    wire [1:0] state_e1;
    wire door_open_e1;

    wire [`FLOOR_BITS-1:0] current_floor_e2;
    wire [1:0] state_e2;
    wire door_open_e2;

    // Instantiate dual elevator system
    dual_elevator_top dut (
        .clk(clk),
        .reset(reset),
        .emergency_stop(emergency_stop),
        .up_calls(up_calls),
        .down_calls(down_calls),
        .destination_e1(destination_e1),
        .destination_e2(destination_e2),
        .current_floor_e1(current_floor_e1),
        .state_e1(state_e1),
        .door_open_e1(door_open_e1),
        .current_floor_e2(current_floor_e2),
        .state_e2(state_e2),
        .door_open_e2(door_open_e2)
    );

    // Clock generation - 10ns period (100 MHz)
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // Stimulus - realistic elevator traffic
    initial begin
        // Initialize
        reset = 1'b1;
        emergency_stop = 1'b0;
        up_calls = {`NUM_FLOORS{1'b0}};
        down_calls = {`NUM_FLOORS{1'b0}};
        destination_e1 = {`NUM_FLOORS{1'b0}};
        destination_e2 = {`NUM_FLOORS{1'b0}};

        $display("Time=%t: ========== ELEVATOR VISUALIZATION SIMULATION ==========", $time);

        #20000;
        reset = 1'b0;
        $display("Time=%t: System active", $time);

        // Request floor 5 from ground floor
        #1000;
        destination_e1[5] = 1'b1;
        #100;
        destination_e1[5] = 1'b0;

        // Request floor 7 for elevator 2
        #500;
        destination_e2[7] = 1'b1;
        #100;
        destination_e2[7] = 1'b0;

        // Wait for elevators to move
        #50000;

        // Request floor 2 from floor 6
        destination_e1[2] = 1'b1;
        #100;
        destination_e1[2] = 1'b0;

        // Request floor 3
        destination_e2[3] = 1'b1;
        #100;
        destination_e2[3] = 1'b0;

        // More requests throughout the simulation to reach ~40 seconds
        #80000;
        destination_e1[7] = 1'b1;
        #100;
        destination_e1[7] = 1'b0;

        #80000;
        destination_e2[0] = 1'b1;
        #100;
        destination_e2[0] = 1'b0;

        #80000;
        destination_e1[4] = 1'b1;
        #100;
        destination_e1[4] = 1'b0;

        #80000;
        destination_e2[6] = 1'b1;
        #100;
        destination_e2[6] = 1'b0;

        // Let simulation continue to ~40 seconds total (need ~3,600,000 more)
        #3600000;

        $display("Time=%t: Visualization simulation complete", $time);
        $finish;
    end

    // Monitoring with simplified format for visualization
    initial begin
        $monitor("Time=%t, E1[F=%0d,S=%0d], E2[F=%0d,S=%0d]",
                 $time,
                 current_floor_e1, state_e1,
                 current_floor_e2, state_e2);
    end

endmodule
