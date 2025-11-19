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
    reg [`NUM_FLOORS-1:0] requests;

    // -- DUT Connections --
    // Use wire for signals driven by the DUT outputs
    wire [`FLOOR_BITS-1:0] current_floor;
    wire door_open;
    wire moving_up;
    wire moving_down;
    wire [1:0] elevator_state; // State is a 2-bit wire

    // -- Instantiate the DUT (Design Under Test) --
    elevator_fsm dut (
        .clk(clk),
        .reset(reset),
        .requests(requests),
        .current_floor(current_floor),
        .door_open(door_open),
        .moving_up(moving_up),
        .moving_down(moving_down),
        .state(elevator_state)
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

    // -- Test Sequence --
    initial begin
        // 1. Initialize signals and assert reset
        $display("Time=%t: Starting simulation. Asserting reset.", $time);
        requests = {`NUM_FLOORS{1'b0}}; // Initialize all bits to 0
        reset = 1'b1;
        #20;

        // 2. De-assert reset. Elevator should be in IDLE at floor 0.
        $display("Time=%t: De-asserting reset.", $time);
        reset = 1'b0;
        #10;
        
        // 3. Request floor 4 and wait
        request_floor(4);
        @(posedge door_open);
        $display("Time=%t: << Elevator arrived at floor 4 and door is open.", $time);
        requests[4] = 1'b0; // Clear the request
        @(negedge door_open);
        $display("Time=%t: << Door closed.", $time);
        #20;

        // 4. Request floor 1 and wait
        request_floor(1);
        @(posedge door_open);
        $display("Time=%t: << Elevator arrived at floor 1 and door is open.", $time);
        requests[1] = 1'b0; // Clear the request
        @(negedge door_open);
        $display("Time=%t: << Door closed.", $time);
        #20;

        // 5. End the simulation
        $display("Time=%t: Simulation finished.", $time);
        $finish;
    end

    // -- Monitoring and Waveform Dumping --
    initial begin
        // Monitor prints a message whenever any of its arguments change.
        // States: 0=IDLE, 1=DOOR_OPEN, 2=MOVING_UP, 3=MOVING_DOWN
        $monitor("Time=%t, Floor=%0d, Requests=%b, DoorOpen=%b, Up=%b, Down=%b, State=%d",
                 $time, current_floor, requests, door_open, moving_up, moving_down, elevator_state);
                 
        $dumpfile("tb/elevator_tb.vcd");
        $dumpvars(0, elevator_tb);
    end

endmodule
