#!/bin/bash
# Script to run the visualization testbench for live animation

echo "=========================================="
echo "  ELEVATOR VISUALIZATION SIMULATION"
echo "=========================================="

# Clean up
rm -f visualization_sim visualization_tb.vcd

# Compile
iverilog -g2001 -o visualization_sim \
    -I src \
    src/elevator_fsm.v \
    src/scheduler.v \
    src/dual_elevator_top.v \
    tb/visualization_tb.v

if [ $? -ne 0 ]; then
    echo "Compilation failed!"
    exit 1
fi

# Run simulation
vvp visualization_sim

# Clean up
rm -f visualization_sim visualization_tb.vcd
