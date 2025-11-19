#!/bin/bash
# Simulation script for single elevator testbench
# Compiles and runs elevator_fsm_tb using Icarus Verilog

echo "========================================="
echo "  Dual Elevator System - Single Elevator Test"
echo "========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Navigate to project root
cd "$(dirname "$0")/.." || exit 1

echo "Step 1: Cleaning previous build artifacts..."
rm -f elevator_sim elevator_tb.vcd
echo -e "${GREEN} Clean complete${NC}"
echo ""

echo "Step 2: Compiling Verilog source files..."
iverilog -g2001 \
    -o elevator_sim \
    -I src \
    src/elevator_fsm.v \
    tb/elevator_tb.v

if [ $? -eq 0 ]; then
    echo -e "${GREEN} Compilation successful${NC}"
else
    echo -e "${RED} Compilation failed${NC}"
    exit 1
fi
echo ""

echo "Step 3: Running simulation..."
echo "----------------------------------------"
vvp elevator_sim

SIM_EXIT_CODE=$?
echo "----------------------------------------"
echo ""

if [ $SIM_EXIT_CODE -eq 0 ]; then
    echo -e "${GREEN} Simulation completed successfully${NC}"
    echo ""
    echo "Generated files:"
    if [ -f "elevator_tb.vcd" ]; then
        echo "  - elevator_tb.vcd - waveform file"
        echo ""
        echo "To view waveforms, run:"
        echo "  gtkwave elevator_tb.vcd"
    fi
else
    echo -e "${RED} Simulation failed with exit code $SIM_EXIT_CODE${NC}"
    exit 1
fi

echo ""
echo "========================================="
echo "  Test Complete"
echo "========================================="
