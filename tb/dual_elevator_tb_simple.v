// Simplified testbench for dual elevator system for debugging
`timescale 1ns / 1ps
`include "config.vh"

module dual_elevator_tb_simple;
    reg clk, reset, emergency_stop;
    reg [`NUM_FLOORS-1:0] up_calls, down_calls, destination_e1, destination_e2;
    
    wire [`FLOOR_BITS-1:0] current_floor_e1, current_floor_e2;
    wire door_open_e1, door_open_e2;
    wire moving_up_e1, moving_down_e1, moving_up_e2, moving_down_e2;
    wire [1:0] state_e1, state_e2;
    wire [`NUM_FLOORS-1:0] debug_pending_dest_e1, debug_pending_dest_e2;

    dual_elevator_top dut (
        .clk(clk), .reset(reset), .emergency_stop(emergency_stop),
        .up_calls(up_calls), .down_calls(down_calls),
        .destination_e1(destination_e1), .destination_e2(destination_e2),
        .current_floor_e1(current_floor_e1), .door_open_e1(door_open_e1),
        .moving_up_e1(moving_up_e1), .moving_down_e1(moving_down_e1), .state_e1(state_e1),
        .current_floor_e2(current_floor_e2), .door_open_e2(door_open_e2),
        .moving_up_e2(moving_up_e2), .moving_down_e2(moving_down_e2), .state_e2(state_e2),
        .debug_pending_dest_e1(debug_pending_dest_e1),
        .debug_pending_dest_e2(debug_pending_dest_e2)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        $display("Starting simple dual elevator test");
        $dumpfile("dual_elevator_simple.vcd");
        $dumpvars(0, dual_elevator_tb_simple);
        
        up_calls = 0; down_calls = 0;
        destination_e1 = 0; destination_e2 = 0;
        reset = 1; emergency_stop = 0;
        #20;
        
        reset = 0;
        $display("Time=%t: Reset released", $time);
        #50;
        
        // Simple test: Single call
        $display("Time=%t: Making call to floor 3", $time);
        up_calls[3] = 1;
        #300;
        
        $display("Time=%t: Test complete", $time);
        $display("E1 at floor %0d, E2 at floor %0d", current_floor_e1, current_floor_e2);
        $finish;
    end

    initial #1000 begin
        $display("ERROR: Timeout - test took too long!");
        $finish;
    end
endmodule
